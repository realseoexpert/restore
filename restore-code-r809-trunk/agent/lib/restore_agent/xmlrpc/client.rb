require 'xmlrpc/client'
module RestoreAgent::XMLRPC
  class Client < ::XMLRPC::Client

    def do_rpc(request, async=false)
      header = {  
        "User-Agent"     =>  USER_AGENT,
        "Content-Type"   => "text/xml; charset=utf-8",
        "Content-Length" => request.size.to_s, 
        "Connection"     => (async ? "close" : "keep-alive")
        }

        header["Cookie"] = @cookie        if @cookie
        header.update(@http_header_extra) if @http_header_extra

        if @auth != nil
          # add authorization header
          header["Authorization"] = @auth
        end

        resp = nil
        @http_last_response = nil

        if async
          # use a new HTTP object for each call 
          Net::HTTP.version_1_2
          http = Net::HTTP.new(@host, @port, @proxy_host, @proxy_port) 
          http.use_ssl = @use_ssl if @use_ssl
          http.read_timeout = @timeout
          http.open_timeout = @timeout

          # post request
          http.start {
            resp = http.post2(@path, request, header) 
          }
          @http_last_response = resp
          process_headers(resp)
          return resp.body

        else
          # reuse the HTTP object for each call => connection alive is possible

          # post request
          data = ''#resp.body
          @http.post2(@path, request, header) do |resp|
            @http_last_response = resp
            process_headers(resp)
            resp.read_body do |segment|
              data += segment
              #puts segment
            end
          end
        return data
      end
    end


    def process_headers(resp)    
      if resp.code == "401"
        # Authorization Required
        raise "Authorization failed.\nHTTP-Error: #{resp.code} #{resp.message}" 
      elsif resp.code[0,1] != "2"
        raise "HTTP-Error: #{resp.code} #{resp.message}" 
      end

      ct = parse_content_type(resp["Content-Type"]).first
      if ct != "text/xml"
        if ct == "text/html"
          raise "Wrong content-type: \n#{data}"
        else
          raise "Wrong content-type"
        end
      end

      expected = resp["Content-Length"] || "<unknown>"
      #    if data.nil? or data.size == 0 
      #      raise "Wrong size. Was #{data.size}, should be #{expected}" 
      #    elsif expected != "<unknown>" and expected.to_i != data.size and resp["Transfer-Encoding"].nil?
      #      raise "Wrong size. Was #{data.size}, should be #{expected}"
      #    end

      c = resp["Set-Cookie"]
      @cookie = c if c
    end
  end
end