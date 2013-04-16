use strict;
use warnings;
use feature qw(state);
use Benchmark qw(cmpthese);

# In today's contest, we'll be comparing Type::Params...
#
use Type::Params qw( compile validate );
use Type::Utils;
use Types::Standard qw( -types );

# ... with Params::Validate...
#
BEGIN { $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS' }; # ... which we'll give a fighting chance
use Params::Validate qw( validate_pos ARRAYREF SCALAR );

# Define custom type constraints...
my $PrintAndSay = duck_type PrintAndSay => ["print", "say"];
my $SmallInt    = declare SmallInt => as Int,
	where     { $_ < 90 },
	inline_as { $_[0]->parent->inline_check($_)." and $_ < 90" };

sub TypeParams_validate
{
	my @in = validate(\@_, ArrayRef, $PrintAndSay, $SmallInt);
}

sub TypeParams_compile
{
	state $spec = compile(ArrayRef, $PrintAndSay, $SmallInt);
	my @in = $spec->(@_);
}

sub ParamsValidate
{
	state $spec = [
		{ type => ARRAYREF },
		{ can  => ["print", "say"] },
		{ type => SCALAR, regex => qr{^\d+$}, callbacks => { 'less than 90' => sub { shift() < 90 } } },
	];
	my @in = validate_pos(@_, @$spec);
}

# Actually run the benchmarks...
#

use IO::Handle ();
our @data = (
	[1, 2, 3],
	IO::Handle->new,
	50,
);

cmpthese(-3, {
	'Type::Params compile'   => q{ TypeParams_compile(@::data) },
	'Params::Validate'       => q{ ParamsValidate(@::data) },
	'Type::Params validate'  => q{ TypeParams_validate(@::data) },
});

__END__
                         Rate Params::Validate Type::Params validate Type::Params compile
Params::Validate      11550/s               --                  -40%                 -64%
Type::Params validate 19185/s              66%                    --                 -40%
Type::Params compile  32036/s             177%                   67%                   --
