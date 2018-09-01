# frozen_string_literal: true

# Class for parsing currencies.
class DataSanitizer
  def initialize(sanitizer_profile = 'connec_sanitizer_profile.yml')
    # Load the configuration profile from - class-level caching required for performance
    # We could have standard configuration profiles stored under the config/ directory (e.g. api_v2_pi_data_masking.yml or qbov3_pi_data_masking.yml)
    @profile = load_sanitizer_profile(sanitizer_profile)
  end

  def sanitize(arg_entity, args, input_profile = nil)
    if args.is_a?(Array)
      args.map do |arg|
        arg = arg[arg_entity] || arg
        sanitize_hash(arg_entity, arg, input_profile)
      end
    else
      args = args[arg_entity] || args
      sanitize_hash(arg_entity, args, input_profile)
    end
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
      case
      when action_or_nested_profile.is_a?(Hash)
        # Nested profile - recursively call the sanitization method
        sanitized_hash[attribute] = sanitize(entity, sanitized_hash[attribute], action_or_nested_profile)
      when action_or_nested_profile == 'hash'
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
    @@sanitizer_configurations ||= {}
    @@sanitizer_configurations[sanitizer_profile] ||= YAML.load(File.read(Rails.root.join('config', 'profiles', sanitizer_profile).to_s))
  end

    # Short attribute digest (Rails secret used as salt)
    # NOTE: hashing attributes will be useful to models which have matching attribute values (e.g. for the reconciliation engine)
    def hash_value(value)
      Digest::SHA1.hexdigest("#{value}-#{Rails.application.secrets.secret_key_base}")
    end
  end
