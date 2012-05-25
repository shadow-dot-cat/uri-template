use strict;
use warnings;

use Test::More;
use Scalar::Util ();

BEGIN {
    eval "use JSON ();";
    plan skip_all => "JSON required" if $@;
    plan( 'no_plan' );
    use_ok( 'URI::Template' );
}

my @files = glob( 't/cases/*.json' );

for my $file ( @files ) {
    open( my $json, $file );
    my $data = do { local $/; <$json> };
    close( $json );

    eval { JSON->VERSION( 2 ) };
    my $suite     = $@ ? JSON::jsonToObj( $data ) : JSON::from_json( $data );

    for my $name ( sort keys %$suite ) {
        my $info  = $suite->{ $name };
        my $vars  = $info->{ variables };
        my $cases = $info->{ testcases };

        diag( sprintf( '%s [level %d]', $name, ( $info->{ level } || 4 ) ) );

        for my $case ( @$cases ) {
            my( $input, $expect ) = @$case;
            my $template = URI::Template->new( $input );
            my $result   = ''; # $template->process( $vars );
             _check_result( $result, $expect, $input );
        }

    }
}

sub _check_result {
    my( $result, $expect, $input ) = @_;

    # boolean
    if( Scalar::Util::blessed( $expect ) ) {
        ok( !defined $result, $input );
    }
    # list of possible results
    elsif( ref $expect ) {
        my $ok = 0;
        for my $e ( @$expect ) {
            if( $result eq $e ) {
                $ok = 1;
                last;
            }
        }
        ok( $ok, $input );
    }
    # exact comparison
    else {
        is( $result, $expect, $input );
    }
}
