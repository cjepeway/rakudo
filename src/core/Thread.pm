# Thread represents an OS-level thread. While it could be used directly, it
# is not the preferred way to work in Perl 6. It's a building block for the
# interesting things.
my class Thread {
    # The VM-level thread handle.
    has Mu $!vm_thread;

    # Is the thread's lifetime bounded by that of the application, such
    # that when it exits, so does the thread?
    has Bool $.app_lifetime;

    # Thread's (user-defined) name.
    has Str $.name;

    submethod BUILD(:&code!, :$!app_lifetime as Bool = False, :$!name as Str = "<anon>") {
        $!vm_thread := nqp::newthread(
            { my $*THREAD = self; code(); },
            $!app_lifetime ?? 1 !! 0);
    }

    method start(Thread:U: &code, *%adverbs) {
        Thread.new(:&code, |%adverbs).run()
    }

    method run(Thread:D:) {
        nqp::threadrun($!vm_thread);
        self
    }

    method id(Thread:D:) {
        nqp::p6box_i(nqp::threadid($!vm_thread));
    }

    method finish(Thread:D:) {
        nqp::threadjoin($!vm_thread);
        self
    }

    multi method Str(Thread:D:) {
        "Thread<$.id>($.name)"
    }

    method yield(Thread:U:) {
        nqp::threadyield();
        Nil
    }
}

{
    my $init_thread := nqp::create(Thread);
    nqp::bindattr($init_thread, Thread, '$!vm_thread', nqp::currentthread());
    nqp::bindattr($init_thread, Thread, '$!app_lifetime', False);
    nqp::bindattr($init_thread, Thread, '$!name', 'Initial thread');
    PROCESS::<$THREAD> := $init_thread;
}