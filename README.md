Shotodol net
=============

This is a collection of modules to write network application using shotodol.

Dependencies
============

You need to get the following project sources,

- [aroop](https://github.com/kamanashisroy/aroop)
- [shotodol](https://github.com/kamanashisroy/shotodol)

Getting the projects
====================

You need to get compressed(tar.gz/zip) distribution from the servers(for example, github.com/kamanashisroy/). Otherwise you can use git to [clone](http://git-scm.com/docs/git-clone) the [repositories](http://en.wikipedia.org/wiki/Repository_%28version_control%29), which is important if you want to change and develop the code or if you want to see the history.

You need to create a project directory for all the associated projects. Then you need to decompress the projects in this directory.

Suppose you are in _'a'_ directory. Then you need to decompress _aroop_,_shotodol_,_shotodol\_net_, in _'a'_ directory. If you are in linux, then putting _'ls'_ command in shell looks like this,

```
 a$ ls 
 aroop shotodol shotodol_net . .. 
```

How to configure
===============

Now you need to build the projects sequentially. Please see the readme in aroop and shotodol to build them.

To build shotodol\_net, you need to configure and generate the makefiles. To do that you need [lua](http://www.lua.org/). And if you have filesystems module in lua then it would be easy. You need to execute the configure.lua script, like the following,

```
 a/shotodol_net$ lua configure.lua
```

And you will get the output like the following,

```
Project path /a/shotodol_net > 
Aroop path /a/aroop > 
Shotodol path /a/shotodol > 
```

How to build shotodol\_net
======================

Now you can easily build shotodol\_net like,

```
 a/shotodol_net$ make
 a/shotodol_net$ ls
	shotodol.bin
```

Modules
=========
- [netio](libs/netio/README.md)

Enjoy !
