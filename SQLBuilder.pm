package SQLBuilder;

use strict;
use warnings;
use Data::Dumper;

# SQLBuilder: a helper class to build SQL

=head1 SYNOPSIS

    use SQLBuilder;
    use DBI;
    my $dbh = DBI->connect(...);

    # you can call it like chain
    my $query = SQLBuilder->SELECT('col1, col2')->FROM('table1')->WHERE('col1 = ?', $val1);

    # you can also call it individually, the statement order doesn't matter
    my $query = SQLBuilder->SELECT->FROM('table');
    $query->LIMIT(100);
    $query->WHERE('col2 = ?', $val2);
    $query->JOIN('LEFT JOIN table2 ON (...)');

    my ($sql, $bind_vars) = $query->build();
    my $data = $dbh->selectall_arrayref($sql, @$bind_vars);


=head1 SAMPLES

=head2 sample 1

    SQLBuilder->SELECT->FROM('table');
    # SQL: "SELECT * FROM table", bind vars: []

=head2 sample 2

    SQLBuilder->SELECT('c1, c2')->FROM('table')->WHERE('c1 > ?', 0);
    # SQL: "SELECT c1, c2 FROM table WHERE c1 > ?", bind_vars: [0]

=head2 sample 3

    $sb = SQLBuilder->SELECT('t1.c1')->FROM('table t1');
    $sb->SELECT('t2.c1');
    $sb->FROM('table2 t2');
    $sb->WHERE('t1.c1 = ? AND t2.c1 = ?', 'v1', 'v2');
    $sb->JOIN('LEFT JOIN table t3 ON (t2.c1 = t3.c1) AND (t3.c1 = ?)', 'v3');

    $sb->LIMIT(10);
    $sb->ORDERBY('t3.c1');
    $sb->GROUPBY('t3.c1');

    # SQL:
    #    SELECT t1.c1, t2.c1 FROM table t1, table2 t2
    #    LEFT JOIN table t3 ON (t2.c1 = t3.c1) AND (t3.c1 = ?)
    #    WHERE
    #        t1.c1 = ? AND t2.c1 = ?
    #    GROUP BY
    #        t3.c1
    #    ORDER BY
    #        t3.c1, t1.c1 DESC
    #    LIMIT 10
    # bind_vars: [ 'v3', 'v1', 'v2' ];
    
=cut

sub new {
    my $class = shift;

    my $self = {
        fields      => [],
        from        => [],
        where       => [],
        where_vars  => [],
        join        => [],
        join_vars   => [],
        group_by    => [],
        having      => [],
        having_vars => [],
        order_by    => [],
        limit       => 0,
    };

    return bless $self, $class;
}

sub SELECT {
    my ( $self, @fields ) = @_;
    my $class = ref($self) || $self;
    $self = $class->new if not ref($self);

    push @{ $self->{'fields'} }, @fields;

    return $self;
}

sub FROM {
    my ( $self, @tables ) = @_;
    push @{ $self->{'from'} }, @tables;
    return $self;
}

sub WHERE {
    my ( $self, $condition, @params ) = @_;
    push @{ $self->{'where'} },      $condition;
    push @{ $self->{'where_vars'} }, @params;
    return $self;
}

sub JOIN {
    my ( $self, $statement, @params ) = @_;
    push @{ $self->{'join'} },      $statement;
    push @{ $self->{'join_vars'} }, @params;
    return $self;
}

sub GROUPBY {
    my ( $self, @fields ) = @_;
    push @{ $self->{'group_by'} }, @fields;
    return $self;
}

sub HAVING {
    my ( $self, $condition, @params ) = @_;
    push @{ $self->{'having'} },      $condition;
    push @{ $self->{'having_vars'} }, @params;
    return $self;
}

sub ORDERBY {
    my ( $self, @fields ) = @_;
    push @{ $self->{'order_by'} }, @fields;
    return $self;
}

sub LIMIT {
    my ( $self, $limit ) = @_;
    $self->{'limit'} = $limit;
    return $self;
}

sub build {
    my $self = shift;

    my @sql  = ();
    my @vars = ();

    push @{ $self->{'fields'} }, '*' if not @{ $self->{'fields'} } > 0;
    push @sql, "SELECT";
    push @sql, "\t". join( ', ', @{ $self->{'fields'} } );

    push @sql, "FROM";
    push @sql, "\t". join( ', ', @{ $self->{'from'} } );

    if ( @{ $self->{'join'} } > 0 ) {
        push @sql, join( "\n", @{ $self->{'join'} } );
        push @vars, @{ $self->{'join_vars'} };
    }

    if ( @{ $self->{'where'} } > 0 ) {
        push @sql,  "WHERE";
        push @sql,  "\t". join( ' AND ', @{ $self->{'where'} } );
        push @vars, @{ $self->{'where_vars'} };
    }

    if ( @{ $self->{'group_by'} } > 0 ) {
        push @sql, "GROUP BY";
        push @sql, "\t". join( ', ', @{ $self->{'group_by'} } );
    }

    if ( @{ $self->{'having'} } > 0 ) {
        push @sql,  "HAVING";
        push @sql,  "\t". join( ' AND ', @{ $self->{'having'} } );
        push @vars, @{ $self->{'having_vars'} };
    }

    if ( @{ $self->{'order_by'} } > 0 ) {
        push @sql, "ORDER BY";
        push @sql, "\t". join( ', ', @{ $self->{'order_by'} } );
    }

    if ( $self->{'limit'} and $self->{'limit'} > 0 ) {
        push @sql, "LIMIT $self->{'limit'}";
    }

    my $result = join( "\n", @sql );
    return ( $result, \@vars );
}

sub dump {
    my $self = shift;

    my ($sql, $vars) = $self->build();
    return "SQLBuilder SQL: \n$sql\n, BindVars: " . Dumper($vars);
}

1;

__END__
