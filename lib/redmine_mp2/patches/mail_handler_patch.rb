module RedmineMp2
	module Patches
	  module MailHandlerPatch

		# Redmine 7: override receive via prepend and call the mp2 variant.
		# The method body below is mp2-specific (only @mp2.at senders, custom
		# support user handling) and intentionally replaces core #receive.
		def receive(email, options={})
			@email = email
			@handler_options = options
			sender_email = email.from.to_a.first.to_s.strip
			# Ignore emails received from the application emission address to avoid hell cycles
			emission_address = Setting.mail_from.to_s.gsub(/(?:.*<|>.*|\(.*\))/, '').strip
			if sender_email.casecmp(emission_address) == 0
			  if logger
				logger.info  "MailHandler: ignoring email from Redmine emission address [#{sender_email}]"
			  end
			  return false
			end
			# Ignore auto generated emails
			self.class.ignored_emails_headers.each do |key, ignored_value|
			  value = email.header[key]
			  if value
				value = value.to_s.downcase
				if (ignored_value.is_a?(Regexp) && value.match(ignored_value)) || value == ignored_value
				  if logger
					logger.info "MailHandler: ignoring email with #{key}:#{value} header"
				  end
				  return false
				end
			  end
			end
			@user = User.find_by_mail(sender_email) if (sender_email.present? && sender_email.end_with?("@mp2.at"))
			if @user && !@user.active?
			  if logger
				logger.info  "MailHandler: ignoring email from non-active user [#{@user.login}]"
			  end
			  return false
			end
			if @user.nil?
			  # Email was submitted by an unknown user
			  case handler_options[:unknown_user]
			  when 'accept'
				@user = User.find_by_mail("support.infomed@mp2.at")
			  when 'create'
				@user = create_user_from_email
				if @user
				  if logger
					logger.info "MailHandler: [#{@user.login}] account created"
				  end
				  add_user_to_group(handler_options[:default_group])
				  unless handler_options[:no_account_notice]
					::Mailer.deliver_account_information(@user, @user.password)
				  end
				else
				  if logger
					logger.error "MailHandler: could not create account for [#{sender_email}]"
				  end
				  return false
				end
			  else
				# Default behaviour, emails from unknown users are ignored
				if logger
				  logger.info  "MailHandler: ignoring email from unknown user [#{sender_email}]"
				end
				return false
			  end
			end
			User.current = @user
			dispatch
		  end
	  end
  end
end

unless MailHandler.included_modules.include? RedmineMp2::Patches::MailHandlerPatch
  MailHandler.prepend RedmineMp2::Patches::MailHandlerPatch
end
