package InGiro::Plugin::Classifier;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/decamelize/;

use Hash::Merge qw/merge/;
use List::MoreUtils qw/uniq/;

use Algorithm::NaiveBayes;
use Algorithm::NaiveBayes::Model::Frequency;

has hide_categorizer => sub { my $nbh = Algorithm::NaiveBayes->restore_state("tools/hide.nbm") };
has map_categorizer => sub { my $nbc = Algorithm::NaiveBayes->restore_state("tools/map_category.nbm") };

sub Algorithm::NaiveBayes::best_guess {
    my $self = shift;
    my $h = $self->predict(@_);
    return [ sort { $h->{$b} <=> $h->{$a} } keys $h->%* ]->[0];
}

sub munge {
    my $r = shift();

    $r->{decamelize(ucfirst $_) =~ s/.+_//r} = (delete $r->{$_})->{value} for (keys $r->%*);

    $r->{$_} =~ s/.+\/// for qw/category place/;
    $r->{$_} = [ split / /, $r->{$_} =~ s/^Point\(//r =~ s/\)$//r ] for qw/coords/;
    return $r;
}

sub rollup {
    my $self = shift;
    my $arr = shift;
    my $res = {};

    for ($arr->@*) {
	my $p = join "\t", $_->{place}, $_->{coords}->@*;
	if ($res->{$p}) {
	    $_->{categories} = [ delete $_->{category}];
	    $res->{$p} = merge($res->{$p}, $_);
	} else {
	    $res->{$p} = $_;
	    $res->{$p}->{categories} = [ delete $res->{$p}->{category}]
	}
    }
    for (values $res->%*) {
	$_->{categories} = [ uniq $_->{categories}->@* ];
	$_->{coords} = [ @{$_->{coords}}[0, 1] ];
    }
    return [ sort { $a->{place} cmp $b->{place} } values $res->%* ]
}

sub classify {
    my $self = shift;
    my $arr = shift;

    my $nbh = $self->hide_categorizer;
    my $nbc = $self->map_categorizer;

    for ($arr->@*) {
	my $categories = { map { $_ => 1 } $_->{categories}->@* };
	$_->{hide}         = $nbh->best_guess(attributes => $categories);
	$_->{map_category} = $nbc->best_guess(attributes => $categories);
    }
    return [ grep { !(delete $_->{hide}) } $arr->@* ]
}


sub register {
    my ($self, $app) = @_;
    $app->log->info("registering " .  __PACKAGE__);
    $app->helper("classify" => sub {
		     my $c   = shift;
		     my $arr = shift;

		     $arr = [ map { munge($_) } $arr->@* ];
		     $arr = $self->rollup($arr);
		     $arr = $self->classify($arr);
		     return $arr
		 })
}

1

