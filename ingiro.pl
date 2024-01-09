#!/usr/bin/env perl
use FindBin qw($Bin);
use lib "$Bin/lib";

use Mojolicious::Lite -signatures;
use Mojo::Util qw/dumper/;

use Mojo::Pg;
use Mojo::Loader qw(load_class);

use InGiro::Pg::Database;


push @{app->routes->namespaces},  'InGiro::Controller';
push @{app->plugins->namespaces}, 'InGiro::Plugin';

plugin 'Config';
plugin 'API';
plugin 'Classifier';

app->types->type(vue => 'text/plain');
app->types->type(glsl => 'text/plain');

helper pg    => sub { state $pg = Mojo::Pg->new(app->config->{pg_data})->database_class('InGiro::Pg::Database') };

get '/' => sub ($c) {
  $c->render(template => 'index');
};

get "/api/v2/route" =>  { controller => 'Directions', action => 'get_directions' };

get "/api/v2/points" => { controller => 'Points',     action => 'get_points' };

get "/api/v2/route/:route_id/points" => { controller => 'Points', action => 'get_points' };

get "/api/v2/wikidata" => { controller => 'Wikidata', action => 'get_points' };

get '/test' => sub ($c) {
    $c->api->graphhopper->directions_p
	->then(sub {
		   $c->log->info(dumper @_);
		   $c->render(text => 'ok');
	       })
};

app->start;
