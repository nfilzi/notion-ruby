# frozen_string_literal: true

require_relative 'utils'
require 'httparty'

module NotionAPI
  # the initial methods available to an instantiated Cloent object are defined
  class Core
    include Utils
    @options = { 'cookies' => { :token_v2 => nil, 'x-active-user-header' => nil }, 'headers' => { 'Content-Type' => 'application/json' } }
    @type_whitelist = 'divider'

    class << self
      attr_reader :options, :type_whitelist, :token_v2, :active_user_header
    end

    attr_reader :clean_id, :cookies, :headers

    def initialize(token_v2, active_user_header)
      @@token_v2 = token_v2
      @@active_user_header = active_user_header
    end

    def get_page(url_or_id)
      # ! retrieve a Notion Page Block and return its instantiated class object.
      # ! url_or_id -> the block ID or URL : ``str``
      clean_id = extract_id(url_or_id)

      request_body = {
        pageId: clean_id,
        chunkNumber: 0,
        limit: 100,
        verticalColumns: false
      }
      jsonified_record_response = get_all_block_info(clean_id, request_body)
      i = 0
      while jsonified_record_response.empty? || jsonified_record_response['block'].empty?
        return {} if i >= 10

        jsonified_record_response = get_all_block_info(clean_id, request_body)
        i += 1
      end

      block_id = clean_id
      block_title = extract_title(clean_id, jsonified_record_response)
      block_type = extract_type(clean_id, jsonified_record_response)
      block_parent_id = extract_parent_id(clean_id, jsonified_record_response)

      raise 'the URL or ID passed to the get_page method must be that of a Page Block.' if block_type != 'page'

      PageBlock.new(block_id, block_title, block_parent_id)
    end

    def children(url_or_id = @id)
      # ! retrieve the children of a block. If the block has no children, return []. If it does, return the instantiated class objects associated with each child.
      # ! url_or_id -> the block ID or URL : ``str``

      children_ids = children_ids(url_or_id)
      if children_ids.empty?
        []
      else
        children_class_instances = []
        children_ids.each { |child| children_class_instances.push(get(child)) }
        children_class_instances
      end
    end

    def children_ids(url_or_id = @id)
      # ! retrieve the children IDs of a block.
      # ! url_or_id -> the block ID or URL : ``str``
      clean_id = extract_id(url_or_id)
      request_body = {
        pageId: clean_id,
        chunkNumber: 0,
        limit: 100,
        verticalColumns: false
      }
      jsonified_record_response = get_all_block_info(clean_id, request_body)
      i = 0
      while jsonified_record_response.empty?
        return {} if i >= 10

        jsonified_record_response = get_all_block_info(clean_id, request_body)
        i += 1
      end

      jsonified_record_response['block'][clean_id]['value']['content'] || []
    end

    private

    def get_notion_id(body)
      # ! retrieves a users ID from the headers of a Notion response object.
      # ! body -> the body to send in the request : ``Hash``
      Core.options['cookies'][:token_v2] = @@token_v2
      Core.options['headers']['x-notion-active-user-header'] = @@active_user_header
      cookies = Core.options['cookies']
      headers = Core.options['headers']
      request_url = URLS[:GET_BLOCK]

      response = HTTParty.post(
        request_url,
        body: body.to_json,
        cookies: cookies,
        headers: headers
      )
      response.headers['x-notion-user-id']
    end

    def get_last_page_block_id(url_or_id)
      # ! retrieve and return the last child ID of a block.
      # ! url_or_id -> the block ID or URL : ``str``
      children_ids(url_or_id).empty? ? [] : children_ids(url_or_id)[-1]
    end

    def get_block_props_and_format(clean_id, block_title)
      request_body = {
        pageId: clean_id,
        chunkNumber: 0,
        limit: 100,
        verticalColumns: false
      }
      jsonified_record_response = get_all_block_info(clean_id, request_body)
      i = 0
      while jsonified_record_response.empty?
        return {:properties => {title: [[block_title]]}, :format => {}} if i >= 10

        jsonified_record_response = get_all_block_info(clean_id, request_body)
        i += 1
      end
      properties = jsonified_record_response['block'][clean_id]['value']['properties']
      formats = jsonified_record_response['block'][clean_id]['value']['format']
      return {
        :properties => properties,
        :format => formats
      }
    end

    def get_all_block_info(_clean_id, body)
      # ! retrieves all info pertaining to a block Id.
      # ! clean_id -> the block ID or URL cleaned : ``str``
      Core.options['cookies'][:token_v2] = @@token_v2
      Core.options['headers']['x-notion-active-user-header'] = @active_user_header
      cookies = Core.options['cookies']
      headers = Core.options['headers']

      request_url = URLS[:GET_BLOCK]

      response = HTTParty.post(
        request_url,
        body: body.to_json,
        cookies: cookies,
        headers: headers
      )

      JSON.parse(response.body)['recordMap']
    end

    def filter_nil_blocks(jsonified_record_response)
      # ! removes any blocks that are empty [i.e. have no title / content]
      # ! jsonified_record_responses -> parsed JSON representation of a notion response object : ``Json``
      jsonified_record_response.empty? || jsonified_record_response['block'].empty? ? nil : jsonified_record_response['block']
    end

    def extract_title(clean_id, jsonified_record_response)
      # ! extract title from core JSON Notion response object.
      # ! clean_id -> the cleaned block ID: ``str``
      # ! jsonified_record_response -> parsed JSON representation of a notion response object : ``Json``
      filter_nil_blocks = filter_nil_blocks(jsonified_record_response)
      if filter_nil_blocks.nil? || filter_nil_blocks[clean_id].nil? || filter_nil_blocks[clean_id]['value']['properties'].nil?
        nil
      else
        # titles for images are called source, while titles for text-based blocks are called title, so lets dynamically grab it
        # https://stackoverflow.com/questions/23765996/get-all-keys-from-ruby-hash/23766007
        title_value = filter_nil_blocks[clean_id]['value']['properties'].keys[0]
        Core.type_whitelist.include?(filter_nil_blocks[clean_id]['value']['type']) ? nil : jsonified_record_response['block'][clean_id]['value']['properties'][title_value].flatten[0] 

      end
    end

    def extract_collection_title(_clean_id, collection_id, jsonified_record_response)
      # ! extract title from core JSON Notion response object.
      # ! clean_id -> the cleaned block ID: ``str``
      # ! collection_id -> the collection ID: ``str``
      # ! jsonified_record_response -> parsed JSON representation of a notion response object : ``Json``
      jsonified_record_response['collection'][collection_id]['value']['name'].flatten.join if jsonified_record_response['collection'] and jsonified_record_response['collection'][collection_id]['value']['name']
    end

    def extract_type(clean_id, jsonified_record_response)
      # ! extract type from core JSON response object.
      # ! clean_id -> the block ID or URL cleaned : ``str``
      # ! jsonified_record_response -> parsed JSON representation of a notion response object : ``Json``
      filter_nil_blocks = filter_nil_blocks(jsonified_record_response)
      if filter_nil_blocks.nil?
        nil
      else
        filter_nil_blocks[clean_id]['value']['type']

      end
    end

    def extract_parent_id(clean_id, jsonified_record_response)
      # ! extract parent ID from core JSON response object.
      # ! clean_id -> the block ID or URL cleaned : ``str``
      # ! jsonified_record_response -> parsed JSON representation of a notion response object : ``Json``
      jsonified_record_response.empty? || jsonified_record_response['block'].empty? ? {} : jsonified_record_response['block'][clean_id]['value']['parent_id']
    end

    def extract_collection_id(clean_id, jsonified_record_response)
      # ! extract the collection ID
      # ! clean_id -> the block ID or URL cleaned : ``str``
      # ! jsonified_record_response -> parsed JSON representation of a notion response object : ``Json``
      jsonified_record_response['block'][clean_id]['value']['collection_id']
    end

    def extract_view_ids(clean_id, jsonified_record_response)
      jsonified_record_response['block'][clean_id]['value']['view_ids'] || []
    end
    
    def extract_id(url_or_id)
      # ! parse and clean the URL or ID object provided.
      # ! url_or_id -> the block ID or URL : ``str``
      http_or_https = url_or_id.match(/^(http|https)/) # true if http or https in url_or_id...
      if (url_or_id.length == 36) && ((url_or_id.split('-').length == 5) && !http_or_https)
        # passes if url_or_id is perfectly formatted already...
        url_or_id
      elsif (http_or_https && (url_or_id.split('-').last.length == 32)) || (!http_or_https && (url_or_id.length == 32))
        # passes if either:
        # 1. a URL is passed as url_or_id and the ID at the end is 32 characters long or
        # 2. a URL is not passed and the ID length is 32 [aka unformatted]
        pattern = [8, 13, 18, 23]
        id = url_or_id.split('-').last
        pattern.each { |index| id.insert(index, '-') }
        id
      else
        raise ArgumentError, 'Expected a Notion page URL or a page ID. Please consult the documentation for further information.'
      end
    end
  end
end
