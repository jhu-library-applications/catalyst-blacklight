require 'open-uri'
require 'cgi'

# Only works for documents with a #to_marc right now. 
class JhSmsSend < ActionMailer::Base
  include ActionView::Helpers::TextHelper # for word_wrap
  
  
  def sms_record(document, holding, options)    
    options[:url_gen_params] ||= {}
                
    # Yeah, good design would put the body in a View Template. But. It's 
    # so simple, and there's enough indirection involved in ActionMailer already,
    # PLUS, it's very hard to control newlines in ERB, and we need to make sure
    # newlines are ONLY where we want them to be. So, although ActionMailer makes
    # us send it to an ERB template anyway, but we just send our whole msg
    # as a param. 
    
    # First no more than 35 chars of title. then location and call number. 
    # then url, tiny-url-ized.     
    body_text = ""
    body_text << word_wrap(document.to_semantic_values[:title][0], :line_width => 35).split("\n")[0] + "\n\n" if document.to_semantic_values[:title]
    body_text << holding.collection.display_label + "\n" if holding.collection
    body_text << holding.call_number + "\n\n" if holding.call_number
    body_text << tinyurl(catalog_url(document[:id], options[:url_gen_params]))
            
    mail(:to => "#{options[:to]}@#{sms_mapping[options[:carrier]]}", :from =>  "no-reply@#{options[:email_from_host]}", :subject => "") do |format| 
      format.text { render :text => body_text }    
    end
  end

  protected
  
  def tinyurl(url)
    begin
      open("http://tinyurl.com/api-create.php?url=#{CGI.escape(url)}").read
    rescue
      # On an error, we just skip the tinyurl and use an ordinary one. 
      url
    end
  end
  
  def sms_mapping
    {'vmobile' => 'vmobl.com',
    'virgin' => 'vmobl.com',
    'att' => 'txt.att.net',
    'verizon' => 'vtext.com',
    'nextel' => 'messaging.nextel.com',
    'sprint' => 'messaging.sprintpcs.com',
    'tmobile' => 'tmomail.net',
    'alltel' => 'message.alltel.com',
    'cricket' => 'mms.mycricket.com'}
  end
end