"/Users/danielmurphy/Desktop/notion-ruby/lib is the abs path."
["/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/executable-hooks-1.6.0/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/extensions/x86_64-darwin-19/2.7.0/executable-hooks-1.6.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/bundler-unload-1.0.2/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/rubygems-bundler-1.4.5/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0/x86_64-darwin19"]
"/Users/danielmurphy/Desktop/notion-ruby/lib is the abs path."
["/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/executable-hooks-1.6.0/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/extensions/x86_64-darwin-19/2.7.0/executable-hooks-1.6.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/bundler-unload-1.0.2/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/rubygems-bundler-1.4.5/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0/x86_64-darwin19"]
"/Users/danielmurphy/Desktop/notion-ruby/lib is the abs path."
["/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/executable-hooks-1.6.0/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/extensions/x86_64-darwin-19/2.7.0/executable-hooks-1.6.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/bundler-unload-1.0.2/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/gems/2.7.0/gems/rubygems-bundler-1.4.5/lib", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/site_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby/2.7.0/x86_64-darwin19", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/vendor_ruby", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0", "/Users/danielmurphy/.rvm/rubies/ruby-2.7.0/lib/ruby/2.7.0/x86_64-darwin19"]
require_relative "types"
require "httparty"

module Notion
  class Block < Types
    include HTTParty
    base_uri "https://www.notion.so/api/v3"

    @@method_urls = {
      :GET_BLOCK => "https://www.notion.so/api/v3/loadPageChunk",
      :UPDATE_BLOCK => "https://www.notion.so/api/v3/", # TODO
    }
    attr_reader :token_v2, :clean_id, :cookies, :headers

    def get_all_block_info(clean_id, body, options = {})
      cookies = !options["cookies"].nil? ? options["cookies"] : { :token_v2.to_s => token_v2 }
      headers = !options["headers"].nil? ? options["headers"] : { "Content-Type" => "application/json" }
      request_url = @@method_urls[:GET_BLOCK]

      response = HTTParty.post(
        request_url,
        :body => body.to_json,
        :cookies => cookies,
        :headers => headers,
      )
      jsonified_record_response = JSON.parse(response.body)["recordMap"]

      return jsonified_record_response
    end

    def extract_title(clean_id, jsonified_record_response)
      # extract title from core JSON response body.
      return jsonified_record_response["block"][clean_id]["value"]["properties"].nil? ? nil : jsonified_record_response["block"][clean_id]["value"]["properties"]["title"].flatten.join(" ")
    end

    def extract_type(clean_id, jsonified_record_response)
      block_type = jsonified_record_response["block"][clean_id]["value"]["type"]
      return block_type
    end

    def extract_children_ids(clean_id, jsonified_record_response)
      return !jsonified_record_response.empty? ? jsonified_record_response["block"][clean_id]["value"]["content"] : {}
    end

    def extract_id(url_or_id)
      begin
        if (url_or_id.length == 36) or (url_or_id.split("-").length == 5)
          return url_or_id
        else
          pattern = [8, 13, 18, 23]
          id = url_or_id.split("-").last
          pattern.each { |index| id.insert(index, "-") }
          return id
        end
      rescue 
        raise "Expected a full page URL or a page ID. Please consult the documentation for further information."
      end
    end

    def get_block(url_or_id, options = {})
      # retrieve the title, type, and ID of a block
      clean_id = extract_id(url_or_id)

      request_body = {
        :pageId => clean_id,
        :chunkNumber => 0,
        :limit => 100,
        :verticalColumns => false,
      }
      jsonified_record_response = get_all_block_info(clean_id, request_body, options)
      i = 0
      while jsonified_record_response.empty?
        if i >= 20
          return {}
        else
          jsonified_record_response = get_all_block_info(clean_id, request_body, options)
          i += 1
        end
      end
      block_id = clean_id
      #TODO: figure out how to best translate notions markdown formatting into plaintext for content delivery.
      # p jsonified_record_response["block"][clean_id]
      block_title = extract_title(clean_id, jsonified_record_response)
      block_type = extract_type(clean_id, jsonified_record_response)
      return block_id, block_title, block_type
    end

    def get_block_children_ids(url_or_id, options = {})
      clean_id = extract_id(url_or_id)
      request_body = {
        :pageId => clean_id,
        :chunkNumber => 0,
        :limit => 100,
        :verticalColumns => false,
      }
      jsonified_record_response = get_all_block_info(clean_id, request_body, options)
      children_ids = extract_children_ids(clean_id, jsonified_record_response)
      return children_ids
    end

    def check_id_length(id)
      if id.length != 32
        return false
      end
      return true
    end
  end
end