package InGiro::Controller::Directions;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/dumper/;
use Hash::Merge qw/merge/;

my $defaults = {
		"profile" =>  "car",
		"avoid" => []
	       };

sub get_directions {
    my $c = shift;
    my $later = $c->render_later->tx;

    my $params = merge ($c->req->params->to_hash, ($c->req->json || {}));
    $c->log->info(__PACKAGE__);
    $c->log->info(dumper $params);

    my $points = [
		  [ reverse split /\,/, $params->{from} ],
		  [ reverse split /\,/, $params->{to} ]
		 ];
    $c->api->graphhopper->directions_p(merge($defaults, { points => $points }))
	->then(sub {
		   my $tx = shift;
		   $c->render(json => $tx->res->json)
	       });
};



1

