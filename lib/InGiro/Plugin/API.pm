package InGiro::Plugin::API;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Loader qw/find_modules load_class/;
use Mojo::Util qw/decamelize/;

my @modules = find_modules __PACKAGE__;


sub register {
    my ($self, $app) = @_;

    $app->log->info("registering " .  __PACKAGE__);

    for my $module (grep { /hh/ || /wiki/i } @modules) {
	my $mod_name = $module;
	if (my $e = load_class $module) {
	    die ref $e ? "Exception: $e" : 'Not found!';
	}

	my $p = __PACKAGE__ . "::";
	my $attr = decamelize($module =~ s/$p//r);
	$app->log->info(sprintf "loading %s as %s", $mod_name, $attr);
	has $attr => sub { $module->new({ app => $app}) };
    }
    $app->helper("api" => sub { return $self })
}

1

