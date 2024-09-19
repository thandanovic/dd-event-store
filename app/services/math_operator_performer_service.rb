class MathOperationPerformerService
    def initialize(action, payload)
      @action = action
      @payload = payload
    end
  
    def perform
      operand1 = @payload[@action["operand1"]]
      operand2 = @action["operand2"]
      result = case @action["operation"]
               when "Add"
                 operand1 + operand2
               when "Subtract"
                 operand1 - operand2
               when "Multiply"
                 operand1 * operand2
               when "Divide"
                 operand1 / operand2
               end
      @payload[@action["result_field"]] = result
    end
  end