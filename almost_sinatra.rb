%w.rack tilt backports date INT TERM..map do |l|
    trap(l){$r.stop} rescue require l
end
$curr_date=Date
$port_num=($curr_date.new.year + 145).abs
puts "== Almost Sinatra/No Version has taken the stage on #$port_num for development with backup from Webrick"

$n=Sinatra=Module.new{
    extend Rack
    # http://hawkins.io/2012/07/rack_from_the_beginning/
    # Rack::Builder creates up a middleware stack. 
    # Each object calls the next one and returns its return value.
  
    rack_builder = Rack::Builder.new
    method_obj = Object.method(:define_method)
    template_regex = /@@ *([^\n]+)\n(((?!@@)[^\n]*\n)*)/m
    rack_request = nil
    # 通过调用`Kernel#method`方法，可以获得一个用`Method`对象表示的方法，
    # 可以以后使用`Method#call`方法对它进行调用

    %w[get post put delete].map do |m|
        # https://stackoverflow.com/questions/19108550/how-does-rubys-operator-work
        # https://ruby-doc.org/core-2.2.0/Module.html#method-i-define_method
        method_obj.(m) do |u,&b|
             # Creates a route within the application.
    #
    #   Rack::Builder.app do
    #     map '/' do
    #       run Heartbeat
    #     end
    #   end
    #
    #
    # This example includes a piece of middleware which will run before requests hit +Heartbeat+.
    #
    # def map(path, &block)
    #     @map ||= {}
    #     @map[path] = block
    # end
            rack_builder.map(u){
                
                run lambda { |env|
                    [
                        200,
                        {"Content-Type"=>"text/html"},
                        #instance_eval在一个对象的向下文中执行块
                        [rack_builder.instance_eval(&b)]
                    ]
                }
            }
        end
    end
    Tilt.default_mapping.lazy_map.map do |k,v|
        method_obj.(k){
            |n,*o|
            
            $t||=(
                # https://ruby-doc.org/stdlib-2.3.1/libdoc/date/rdoc/Date.html#method-c-_jisx0301
                # Returns a hash of parsed elements.
                h=$curr_date._jisx0301("hash, please")
                File.read(caller[0][/^[^:]+/]).scan(template_regex){|a,b|h[a]=b}
                h
            )
            # n=="#{n}" to test n is a string
            Kernel.const_get(v[0][0]).new(*o){n=="#{n}"?n:$t[n.to_s]}
            .render(rack_builder,o[0]
            .try(:[],:locals)||{})
        }
    end
    #  [[1,2,3,4]].map do |*_, m|
    #    p m
    #  end  
    # return 4
    %w[set enable disable configure helpers use register].each do |m|
        method_obj.(m) do |*_,&b| 
            b.try :[]
        end
    end
    END{Rack::Handler.get("webrick").run(rack_builder,Port:$port_num){|s|$r=s}}
    %w[params session].map{|m|method_obj.(m){rack_request.send m}};
    rack_builder.use Rack::Session::Cookie
    rack_builder.use Rack::Lock
    method_obj.(:before){|&b|rack_builder.use Rack::Config,&b}
    before do |e|
        rack_request=Rack::Request.new e
        rack_request.params.dup.map{|k,v|params[k.to_sym]=v}
    end
}