# frozen_string_literal: true

# Class for sanitizing data.
module Maestrano::Connector::Rails::Services
  class DataSanitizer
    def initialize(sanitizer_profile = 'connec_sanitizer_profile.yml')
      @profile = load_sanitizer_profile(sanitizer_profile)
    end

    def sanitize(arg_entity, args, input_profile = nil)
      return args unless @profile
      if args.is_a?(Array)
        args.map do |arg|
          arg = arg[arg_entity] || arg
          if arg.is_a?(Array)
            sanitize(arg_entity, arg, input_profile)
          else
            sanitize_hash(arg_entity, arg, input_profile)
          end
        end
      else
        args = args[arg_entity] || args
        if args.is_a?(Array)
          sanitize(arg_entity, args, input_profile)
        else
          sanitize_hash(arg_entity, args, input_profile)
        end
      end
    end

    private

      def sanitize_array(arg_entity, arg_hash, input_profile = nil)
        #
      end

      def sanitize_hash(arg_entity, arg_hash, input_profile = nil)
        # Format arguments
        entity = arg_entity.underscore
        sanitized_hash = arg_hash.deep_dup
        profile = input_profile || @profile[entity]
        return sanitized_hash if profile.nil?
        # Go through each attribute specified in the entity sanitization profile and take action
        # If action is a hash (= nested attributes), recusively call the method
        profile.each do |attribute, action_or_nested_profile|
          next if sanitized_hash[attribute].blank?

          if action_or_nested_profile.is_a?(Hash)
            # Nested profile - recursively call the sanitization method
            sanitized_hash[attribute] = sanitize(entity, sanitized_hash[attribute], action_or_nested_profile)
          elsif action_or_nested_profile == 'hash'
            # Hash the attribute (replaced by a digest value)
            sanitized_hash[attribute] = hash_value(sanitized_hash[attribute])
          else
            # action is 'suppress' (or anything else) => remove the attribute
            sanitized_hash[attribute] = nil
          end
        end

        sanitized_hash
      end

      def load_sanitizer_profile(sanitizer_profile = 'connec_sanitizer_profile.yml')
        return nil unless profile_exists?(sanitizer_profile)
        @@sanitizer_configurations ||= {}
        @@sanitizer_configurations[sanitizer_profile] ||= YAML.safe_load(File.read(Rails.root.join('config', 'profiles', sanitizer_profile).to_s))
      end

      def profile_exists?(profile)
        File.file?(Rails.root.join('config', 'profiles', profile))
      end

      def hash_value(value)
        cipher = OpenSSL::Cipher.new('AES-128-ECB').encrypt
        cipher.key = Rails.application.secrets.secret_key_base[0..15]
        crypt = cipher.update(value.to_s) + cipher.final
        Base64.encode64(crypt)
      end
  end
end
