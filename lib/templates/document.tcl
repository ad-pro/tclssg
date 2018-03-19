# Tclssg, a static website generator.
# Copyright (C) 2013, 2014, 2015, 2016, 2017, 2018 dbohdan.
# This code is released under the terms of the MIT license. See the file
# LICENSE for details.

namespace eval ::document {}
template-proc ::document::render {} {<!DOCTYPE html>
<html>
  <head>
    <%! setting {head top} {} %>
    <meta charset="<%! config charset UTF-8 %>">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <% if {[setting description] ne {%NULL%}} { %>
      <meta name="description" content="<%! entities [setting description] %>">
    <% } %>

    <% if {[config url] ne {%NULL%}} { %>
      <link rel="canonical" href="<%! file join [config url] $::output %>">
    <% } %>
    <% if {$::prevPage ne {}} { %>
      <link rel="prev" href="<%! entities $::prevPage %>">
    <% } %>
    <% if {$::nextPage ne {}} { %>
      <link rel="next" href="<%! entities $::nextPage %>">
    <% } %>
    <% if {[setting favicon] ne {%NULL%}} { %>
      <link rel="icon" href="<%! file join $::root [setting favicon] %>">
    <% } %>
    <% if {[blog-post?] && [config {rss enable} 0]} { %>
      <link rel="" type="application/rss+xml" href="<%! rss-feed %>">
    <% } %>
    <% if {$::prevPage ne {%NULL%} || $::nextPage ne {%NULL%} ||
           [setting noIndex 0]} {
      # Tell search engines to not index the tag pages or the blog index
      # beyond the first page.
    %>
      <meta name="robots" content="noindex">
    <% } %>
    <title><%! document-title %></title>

    <!-- Bootstrap core CSS -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u" crossorigin="anonymous">
    <!-- Bootstrap theme -->
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap-theme.min.css" integrity="sha384-rHyoN1iRsVXV4nD0JutlnGaslCJuC7uwjduW9SVrLvRYooPp2bWYgmgJQIXwl/Sp" crossorigin="anonymous">
    <!-- Custom stylesheets, if any -->
    <% foreach cssLink [setting customCSS {}] { %>
      <link href="<%! url-join $::root $cssLink %>" rel="stylesheet">
    <% } %>
    <%! setting {head bottom} {} %>
  </head>

  <body>
    <%! setting {body top} {} %>
    <div class="navbar navbar-default">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="<%= $::root %>"><%! navbar-brand %></a>
        </div>
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
          <% foreach {item link} [setting navbarItems {}] { %>
            <li><a href="<%! file join $::root $link %>"><%= $item %></a></li>
          <% } %>
          </ul>
        <% if {[blog-post?] && [config {rss enable} 0]} { %>
          <ul class="nav navbar-nav navbar-right">
            <li><a rel="alternate" type="application/rss+xml" href="<%! rss-feed %>"><%=
              ([setting tagPageTag] ne {%NULL%}) && ([config {rss tagFeeds} 0]) ?
              [mc "Tag RSS"] : [mc "RSS"]
            %></a></li>
          </ul>
        <% } %>
        </div><!--/.nav-collapse -->
      </div>
    </div>


    <div class="container">
      <div class="row">
        <% if {[sidebar-note?] ||
               ([blog-post?] && ([sidebar-links?] || [tag-cloud?]))} { %>
          <%
            lassign [content-and-sidebar-class] content_class sidebar_class
          %>
          <section class="<%= $content_class %>">
            <%! content %>
            <%! prev-next-link {« Newer posts} {Older posts »} %>
          </section>
          <div class="<%= $sidebar_class %> well content">
            <%! if {[sidebar-note?]} sidebar-note %>
            <%! if {[sidebar-links?]} sidebar-links %>
            <%! if {[tag-cloud?]} tag-cloud %>
          </div>
         <% } else { %>
          <section class="<%! setting gridClassPrefix col-md- %>12 content">
            <%! content %>
            <%! prev-next-link {« Newer posts} {Older posts »} %>
          </section>
        <%  }
        %>
        <div>

        </div>
      </div>


      <%! comments %>


      <footer class="footer">
        <%! footer %>
      </footer>

    </div><!-- /container -->


    <!-- Bootstrap core JavaScript
    ================================================== -->
    <!-- Placed at the end of the document so the pages load faster -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/js/bootstrap.min.js" integrity="sha384-Tc5IQib027qvyjSMfHjOMaLkfuWVxZxUPnCJA7l2mCWNIpG9mGCD8wGNIcPD7Txa" crossorigin="anonymous"></script>
    <%! setting {body bottom} {} %>
</html>}

namespace eval ::document {
    proc content {} {
        set result {}
        set ::abbreviate [expr {
            $::collection && [config abbreviate 1]
        }]
        foreach ::articleInput $::articles {
            set ::content [db input get $::articleInput cooked]
            append result [::article::render]
            set ::collectionTop 0
        }        
        # TODO: Get rid of this hack?
        namespace path ::document

        return $result
    }

    proc blog-post? {} {
        return [setting blogPost 0]
    }

    proc sidebar-links? {} {
        return [expr {
            [blog-post?] && [setting showSidebarLinks 1]
        }]
    }

    proc sidebar-note? {} {
        return [setting showSidebarNote 1]
    }

    proc tag-cloud? {} {
        return [expr {
            [blog-post?] && [setting showSidebarTagCloud 1]
        }]
    }

    proc content-and-sidebar-class {} {
        set class_prefix [setting gridClassPrefix col-md-]
        set content_column_width [setting contentColumns 8]
        set sidebar_column_width [expr {12 - $content_column_width}]
        set content_class $class_prefix$content_column_width
        set sidebar_class $class_prefix$sidebar_column_width
        if {[setting sidebarPosition right] eq {left}} {
            append content_class " ${class_prefix}push-$sidebar_column_width"
            append sidebar_class " ${class_prefix}pull-$content_column_width"
        }
        return [list $content_class $sidebar_class]
    }

    proc pick-at-most {list limit} {
        if {[string is integer -strict $limit] && ($limit >= 0)} {
            return [lrange $list 0 [expr {$limit - 1}]]
        } else {
            return $list
        }
    }

    proc document-title {} {
        set websiteTitle [config websiteTitle {}]

        set sep { | }

        set pageTitle [setting title {}]
        set showTitle [setting showTitle 1]
        set tagPageTag {}

        set result {}
        if {($showTitle) && ($pageTitle ne "")} {
            lappend result $pageTitle
        }

        if {$tagPageTag ne ""} {
            lappend result [format [mc {Posts tagged "%1$s"}] $tagPageTag]
        }

        if {[info exists ::pageNumber]
            && [string is integer $::pageNumber]
            && ($::pageNumber > 1)} {
            lappend result [format [mc {page %1$s}] $::pageNumber]
        }
        if {$websiteTitle ne ""} {
            lappend result $websiteTitle
        }

        return [entities [join $result $sep]]
    }

    proc rss-feed {} {
        return [file join $::root blog/rss.xml]
    }

    proc navbar-brand {} {
        return [setting navbarBrand [config websiteTitle {}]]
    }

    proc sidebar-links {} {
        # Blog sidebar.
        set sidebar {}
        if {[sidebar-links?]} {
            append sidebar "<nav class=\"sidebar-links\"><h3>[mc Posts]</h3><ul>"

            # Limit the number of posts linked to according to maxSidebarLinks.
            set sidebarPostIds [config sidebarPostIds {}]
            set maxSidebarLinks [config maxSidebarLinks inf]

            foreach id [pick-at-most $sidebarPostIds $maxSidebarLinks] {
                append sidebar [format-link $id]
            }
            append sidebar {</ul></nav><!-- sidebar-links -->}
        }
        return $sidebar
    }


    proc sidebar-note {} {
        return [format \
                {<div class="sidebar-note">%s</div><!-- sidebar-note -->} \
                [setting sidebarNote ""]]
    }

    proc prev-next-link {prevLinkTitle nextLinkTitle} {
        # Blog "next" and "previous" blog index page links.
        set links {}
        if {[blog-post?] && (($::prevPage ne {}) || ($::nextPage ne {}))} {
            append links {<nav class="prev-next text-center"><ul class="pager">}
            if {$::prevPage ne {}} {
                append links "<li class=\"previous\">[rel-link \
                        $::prevPage [mc $prevLinkTitle]]</li>"
            }
            if {$::nextPage ne {}} {
                append links "<li class=\"next\">[rel-link \
                        $::nextPage [mc $nextLinkTitle]]</li>"
            }
            append links {</ul></nav><!-- prev-next -->}
        }
        return $links
    }

    proc tag-cloud {} {
        # Blog tag cloud. For each tag it links to pages that are tagged with it.
        set tagCloud {}

        # Limit the number of tags listed to according to maxTagCloudTags.
        set maxTagCloudTags [config maxTagCloudTags inf]
        if {![string is integer -strict $maxTagCloudTags]} {
            set maxTagCloudTags -1
        }
        set tags [db tags list [config sortTagsBy name] $maxTagCloudTags]

        append tagCloud "<nav class=\"tag-cloud\"><h3>[mc Tags]</h3><ul>"

        foreach tag $tags {
            append tagCloud <li>[tag-page-link $tag]</li>
        }
        append tagCloud {</ul></nav><!-- tag-cloud -->}

        return $tagCloud
    }

    proc footer {} {
        # Footer.
        set footer {}
        set copyright [string map [list \$root $::root \
                                        \$year [clock format [clock seconds] \
                                                             -format %Y]] \
                                  [config copyright {}]]
        if {$copyright ne ""} {
            append footer "<div class=\"copyright\">$copyright</div>"
        }
        if {[setting showFooter 1]} {
            append footer {<div class="powered-by"><small>Powered by <a href="https://github.com/tclssg/tclssg">Tclssg</a> and <a href="http://getbootstrap.com/">Bootstrap</a></small></div>}
        }
        return $footer
    }

    proc comments {} {
        set engine [config {comments engine} none]
        set result {}
        if {[setting showUserComments 1]} {
            switch -nocase -- $engine {
                disqus { set result [comments-disqus] }
                none {}
                {} {}
                default { error "comments engine $engine not found" }
            }
        }
        if {$result eq ""} {
            return ""
        } else {
            return "<div class=\"comments\">$result</div>"
        }
    }

    proc comments-disqus {} {
        set disqusShortname [config {comments disqusShortname} {}]
        set result [string map [list {%disqusShortname} $disqusShortname] {
            <div id="disqus_thread"></div>
            <script type="text/javascript">
            /* * * CONFIGURATION VARIABLES: EDIT BEFORE PASTING INTO YOUR WEBPAGE * * */
            var disqus_shortname = '%disqusShortname'; // required: replace example with your forum shortname
            /* * * DON'T EDIT BELOW THIS LINE * * */
            (function() {
                var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';
                (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
            })();
            </script>
            <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>
            <a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
        }]
        return $result
    }
}