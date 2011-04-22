A TurboGears 2 inspired full stack framework for Node.js written in CoffeeScript.
Still heavily under progress, but someone might find this one actually useful already.

Background
==========

I have been using TurboGears 2.0 / Pylons infrastructure on Python recently; I have noticed
many shortcomings in the existing Node.js frameworks. None of the projects fulfilled my needs, 
so I had to roll out yet another framework. Most notable deficiencies in all existing frameworks
were

-   None really supported configuration files. In Pylons/TurboGears, the full stack
    can be configured in the configuration file. This has the advantage of rolling out
    a slightly different configuration for testing by just changing the startup configuration 
    file.

-   Seriously speaking, the pattern-dispatch url routing (invented by RoR?) is the most brain 
    damaged pattern ever. TurboGears 2.0 provided an alternative, whereby a part of hierarchy
    would be mapped to a class or a class instance, with its methods as the verbs. This allows
    one to construct complex hierarchies, and mount some hierarchies to multiple locations,
    without any code reuse.

    Suppose your system has two kinds of commentable objects: users and articles. You
    can then have a single CommentController mapped to both /user/123/comments and 
    /article/456/comments, with slightly differing semantics; but other routing would
    not need to know the url hierarchy below the comments portion

-   No existing framework supported internationalization, period. Yeah, some projects did 
    claim they do it, but no. No gettext support, no proper embedding in templates, nothing.
    The translatable strings need to be there where they are used. None of the existing 
    frameworks did support this though

-   Many embedded template frameworks did not support effortless async rendering! What 
    is the point in having the complexity of asynchronous language if you cannot throw
    some promises to your template?

-   Reinvent the wheel. Many frameworks roll out their half-assed tools and templating
    languages etc. Robusta is built on Express and tries to use it as much as possible.
    The template engine is Dust, whose syntax is a bit awkward and it is quite far from
    such a gem as Genshi, but it was the only sane engine available that would allow us 
    to roll out i18n support and would support asynchronous rendering. 


Goals
=====

The goals of this project are to include the following features:

-   url routing by traversing property graph (implemented).
-   extendable, yet easy, server configuration using subclassing (started).
-   pluggable mechanisms for authentication, sessions, caching, etc. (well
    you might use express facilities for now)
-   embedded i18n both in the client side scripts and on the server side. 
-   MO/PO files compiled to JSON
-   currently achievable with the attached python tool
-   integrated templating with full support for promises. (using dust)
-   extensive debugging support.

Requirements
============

-   Express framework  (http://expressjs.com/)
-   CoffeeScript 1.0 (http://jashkenas.github.com/coffee-script/)
-   Dust (http://akdubya.github.com/dustjs/)
