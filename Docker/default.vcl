

# specify the VCL syntax version to use
vcl 4.1;

# import vmod_dynamic for better backend name resolution
import dynamic;


import std;
import bodyaccess;
# we won't use any static backend, but Varnish still need a default one
backend default none;
sub vcl_init {
        new d = dynamic.director(port = "80");
}

sub vcl_recv {
	unset req.http.X-Body-Len;
	# force the host header to match the backend (not all backends need it,
	# but example.com does)
	set req.http.host = "graphql.website.com";
	# set the backend
	set req.backend_hint = d.backend("graphql.website.com");




if (req.method == "POST" && req.url ~ "graphql/$") {
    std.log("Will cache POST for: " + req.http.host + req.url);
    std.cache_req_body(500KB);
    set req.http.X-Body-Len = bodyaccess.len_req_body();
    if (req.http.X-Body-Len == "-1") {
        return(synth(400, "The request body size exceeds the limit"));
    }
    return (hash);
}



}



sub vcl_hash {
    # To cache POST and PUT requests
    if (req.http.X-Body-Len) {
        bodyaccess.hash_req_body();
    } else {
        hash_data("");
    }
}




sub vcl_backend_fetch {
    if (bereq.http.X-Body-Len) {
        set bereq.method = "POST";
    }
}

sub vcl_backend_response {
   
        set beresp.ttl = 300s;
    
}
