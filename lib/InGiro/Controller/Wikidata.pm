package InGiro::Controller::Wikidata;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw/dumper decamelize/;

use Hash::Merge qw/merge/;

sub get_points {
    my $c = shift;
    my $params = merge ($c->req->params->to_hash, ($c->req->json || {}));

    my $later = $c->render_later->tx;

    if ($params->{around}) {
	$c->api->wikidata->around_p([ split /\s*\,\s*/, $params->{around} ])
	    ->then(sub {
		       my $json = shift()->res->json;
		       $json = $c->classify($json->{results}->{bindings});
		       $c->render(json => $json)
		   })
	    ->catch(sub {
			$c->reply->json_exception(shift());
		    });
    }
    elsif ($params->{inside}) {
	my @bbox = split /\s*\,\s*/, $params->{inside};
	$c->api->wikidata->inside_p(\@bbox)
	    ->then(sub {
		       my $tx = shift;
		       $c->render(json => $tx->res->json)
		   })
	    ->catch(sub {
			$c->reply->json_exception(shift());
		    });
    }
    else {
	return $c->reply->json_exception("Bad request")
    }
};


1

