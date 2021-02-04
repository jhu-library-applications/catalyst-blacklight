class ApplicationMailer < ActionMailer::Base
  default from: '"Johns Hopkins Libraries" <catalog@jhu.edu>'
  layout 'mailer'
end

