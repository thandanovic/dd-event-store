module WorkflowHelper
    def get_value(payload, value)
      value.gsub(/\{\{(\w+)\}\}/) do |match|
        field = match[2..-3]
        payload.fetch(field, match)
      end
    end
  
    def send_email(action, payload)
      # Implementation to send an email
    end
  
    def generate_document(action, payload)
      # Implementation to generate a document
    end
  
    def send_sms(action, payload)
      # Implementation to send an SMS
    end
  
    module_function :get_value, :send_email, :generate_document, :send_sms
  end