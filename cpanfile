requires 'perl', '5.014';
requires 'App::Greple', '8.57';
requires 'Term::ReadKey';
requires 'App::ansifold', '1.14';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

