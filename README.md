SQLBuilder
==========

A SQL builder in Perl, simple but enough

##SYNOPSIS

    use SQLBuilder;
    use DBI;
    my $dbh = DBI->connect(...);

You can call it like chain

    my $query = SQLBuilder->SELECT('col1, col2')->FROM('table1')->WHERE('col1 = ?', $val1);

You can also call it individually, the statements order doesn't matter

    my $query = SQLBuilder->SELECT->FROM('table');
    $query->LIMIT(100);
    $query->WHERE('col2 = ?', $val2);
    $query->JOIN('LEFT JOIN table2 ON (...)');

Finally, call build to get SQL and bind vars

    my ($sql, $bind_vars) = $query->build();
    my $data = $dbh->selectall_arrayref($sql, @$bind_vars);


##SAMPLES

###sample 1

       SQLBuilder->SELECT->FROM('table');
       # SQL: "SELECT * FROM table", bind vars: []

###sample 2

       SQLBuilder->SELECT('c1, c2')->FROM('table')->WHERE('c1 > ?', 0);
       # SQL: "SELECT c1, c2 FROM table WHERE c1 > ?", bind_vars: [0]

###sample 3

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


