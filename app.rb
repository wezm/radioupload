require 'sinatra/base'

module Radiopaedia

  class TokenError < StandardError; end

  class Uploader < Sinatra::Base

    post "/images/:token" do |token|
      begin
        file = build_file(token)
      rescue TokenError => e
        halt 400, {'Content-Type' => 'text/plain'}, e.message
      end

      if request.media_type != "image/jpeg"
        halt 406, {'Content-Type' => 'text/plain'}, "Content-Type must be image/jpeg"
      end

      if request.content_length.to_i < 8
        halt 406,  {'Content-Type' => 'text/plain'}, "Content-Length is too small to be an image"
      end

      if !file.dirname.exist?
        file.dirname.mkpath
      end

      file.open("wb") do |f|
        IO.copy_stream(request.body, f)
      end

      location = url(file_path(file))

      status 201
      content_type "text/plain"
      headers 'Location' => location
      body "Created: #{location}"
    end

    get "/images/:token/:id" do |token, id|
      begin
        file = find_file(token, id)
      rescue TokenError => e
        halt 400, {'Content-Type' => 'text/plain'}, e.message
      end

      if file.nil?
        not_found
      else
        send_file file
      end
    end

  protected

    def build_file(token)
      uploads.join(sanitize(token), "#{Time.now.utc.to_i}.jpg")
    end

    def find_file(token, id)
      file = uploads.join(sanitize(token), sanitize(id) + ".jpg")
      file.to_s if file.exist?
    end

    def file_path(file)
      "/images/#{file.dirname.basename}/#{file.basename('.jpg')}"
    end

    def uploads
      Pathname(__FILE__).parent + 'uploads'
    end

    def sanitize(name)
      sanitized = name.gsub(/[^a-z0-9]+/, '')[0,32]
      raise TokenError, "Invalid value #{name.inspect}" if sanitized.empty?
      sanitized
    end

  end


end

