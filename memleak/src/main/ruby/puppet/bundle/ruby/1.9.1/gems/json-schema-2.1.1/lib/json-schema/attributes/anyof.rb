module JSON
  class Schema
    class AnyOfAttribute < Attribute
      def self.validate(current_schema, data, fragments, processor, validator, options = {})
        # Create an array to hold errors that are generated during validation
        errors = []
        valid = false

        current_schema.schema['anyOf'].each do |element|
          schema = JSON::Schema.new(element,current_schema.uri,validator)

          # We're going to add a little cruft here to try and maintain any validation errors that occur in the anyOf
          # We'll handle this by keeping an error count before and after validation, extracting those errors and pushing them onto a union error
          pre_validation_error_count = validation_errors(processor).count

          begin
            schema.validate(data,fragments,processor,options)
            valid = true
          rescue ValidationError
            # We don't care that these schemas don't validate - we only care that one validated
          end

          diff = validation_errors(processor).count - pre_validation_error_count
          valid = false if diff > 0
          while diff > 0
            diff = diff - 1
            errors.push(validation_errors(processor).pop)
          end

          break if valid
        end

        if !valid
          message = "The property '#{build_fragment(fragments)}' of type #{data.class} did not match one or more of the required schemas"
          validation_error(processor, message, fragments, current_schema, self, options[:record_errors])
          validation_errors(processor).last.sub_errors = errors
        end
      end
    end
  end
end