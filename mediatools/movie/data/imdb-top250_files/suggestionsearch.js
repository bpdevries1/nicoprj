(function(e){function f(){}function o(b){A=[b]}function q(b,d,h,p){try{p=b&&b.apply(d.context||d,h)}catch(B){p=false}return p}function C(b){return/\?/.test(b)?"&":"?"}function K(b){function d(k){L++||(M(),i&&(D[j]={s:[k]}),B&&(k=B.apply(b,[k])),q(b.success,b,[k,x]),q(p,b,[b,x]))}function h(k){L++||(M(),i&&k!=E&&(D[j]=k),q(b.error,b,[b,k]),q(p,b,[b,k]))}b=e.extend({},a,b);var p=b.complete,B=b.dataFilter,N=b.callbackParameter,l=b.callback,O=b.cache,i=b.pageCache,V=b.charset,j=b.url,t=b.data,W=b.timeout,
P,L=0,M=f,g,F,T;return b.abort=function(){!L++&&M()},q(b.beforeSend,b,[b])===false||L?b:(j=j||u,t=t?typeof t=="string"?t:e.param(t,b.traditional):u,j+=t?C(j)+t:u,N&&(j+=C(j)+encodeURIComponent(N)+"=?"),!O&&!i&&(j+=C(j)+"_"+(new Date).getTime()+"="),j=j.replace(/=\?(&|$)/,"="+l+"$1"),i&&(P=D[j])?P.s?d(P.s[0]):h(P):(y[l]=o,g=e(r)[0],g.id=v+U++,V&&(g[G]=V),c&&c.version()<11.6?((F=e(r)[0]).text="document.getElementById('"+g.id+"')."+z+"()"):(g[Q]=Q),!(H in g)&&I in g&&(g.htmlFor=g.id,g.event=w),g[H]=
g[z]=g[I]=function(k){if(!g[m]||/loaded|complete/.test(g[m])){try{g[w]&&g[w]()}catch(X){}k=A;A=0;k?d(k[0]):h(J)}},g.src=j,M=function(){T&&clearTimeout(T);g[I]=g[H]=g[z]=null;s[n](g);F&&s[n](F)},s[R](g,S),F&&s[R](F,S),T=W>0&&setTimeout(function(){h(E)},W)),b)}var Q="async",G="charset",u="",J="error",R="insertBefore",v="_jqjsp",w="onclick",z="on"+J,H="onload",I="onreadystatechange",m="readyState",n="removeChild",r="<script>",x="success",E="timeout",y=window,s=e("head")[0]||document.documentElement,
S=s.firstChild,D={},U=0,A,a={callback:v,url:location.href},c=y.opera;K.setup=function(b){e.extend(a,b)};e.jsonp=K})(jQuery);var suggestionsearch_enable=function(){jQuery("#navbar-query").searchAutocomplete({maxResults:6,alwaysScrollIntoView:false,resultsDiv:jQuery("#navbar-suggestionsearch"),keyboardControl:true});jQuery("#navbar-query").attr("autocomplete","off");repositionSuggestionSearch()},repositionSuggestionSearch=function(){var e=jQuery("#navbar-query"),f=e.position(),o=e.width();e=e.height();jQuery("#navbar-suggestionsearch").css({left:f.left+0+"px",top:f.top+e+11+"px",width:o+115+"px"})},suggestionsearch_disable=
function(){jQuery("#navbar-query").stopSearchAutocomplete({resultsDiv:jQuery("#navbar-suggestionsearch")});jQuery("#navbar-query").attr("autocomplete","on")},suggestionsearch_dropdown_choice=function(e){"all"==e.value?suggestionsearch_enable():suggestionsearch_disable()};function trackAndClick(e,f,o){(new Image).src="/rg/"+e+"/"+f+"/images/b.gif";setTimeout(function(){document.location=o.href},0);return false}
jQuery(document).ready(function(){var e=jQuery('#nb_search select[name="s"]');if(e.length>0){e=e[0];suggestionsearch_dropdown_choice(e)}});
(function(e){e.fn.searchAutocomplete=function(f){function o(a){q();jQuery(a).addClass("highlighted")}function q(){n.find("a.highlighted").removeClass("highlighted")}function C(){var a=n.find("a.highlighted");a.length>0?a.first().click():jQuery("#navbar-form").submit()}function K(){if(n.find("a").length>0){var a=n.find("a.highlighted");if(a.length>0){a=a.first();var c=a.prev("a");c.length>0&&c.first().addClass("highlighted");a.removeClass("highlighted")}}}function Q(){var a=n.find("a");if(a.length>
0){var c=n.find("a.highlighted");if(c.length>0){a=c.first();c=a.next("a");if(c.length>0){c.first().addClass("highlighted");a.removeClass("highlighted")}}else a.first().addClass("highlighted")}}function G(){repositionSuggestionSearch();n.css("display","block")}function u(){n.css("display","none")}function J(a){if(a){a=a.toLowerCase();if(a.length>20)a=a.substr(0,20);a=a.replace(/^\s*/,"").replace(/[ ]+/g,"_");if(U.test(a))a=a.replace(/[\u00e0\u00c0\u00e1\u00c1\u00e2\u00c2\u00e3\u00c3\u00e4\u00c4\u00e5\u00c5\u00e6\u00c6]/g,
"a").replace(/[\u00e7\u00c7]/g,"c").replace(/[\u00e8\u00c8\u00e9\u00c9\u00ea\u00ca\u00eb\u00cb]/g,"e").replace(/[\u00ec\u00cd\u00ed\u00cd\u00ee\u00ce\u00ef\u00cf]/g,"i").replace(/[\u00f0\u00d0]/g,"d").replace(/[\u00f1\u00d1]/g,"n").replace(/[\u00f2\u00d2\u00f3\u00d3\u00f4\u00d4\u00f5\u00d5\u00f6\u00d6\u00f8\u00d8]/g,"o").replace(/[\u00f9\u00d9\u00fa\u00da\u00fb\u00db\u00fc\u00dc]/g,"u").replace(/[\u00fd\u00dd\u00ff]/g,"y").replace(/[\u00fe\u00de]/g,"t").replace(/[\u00df]/g,"ss");return a=a.replace(/[\W]/g,
"")}return""}function R(){w(m.val())}function v(a,c){if(a&&c&&c.length<=a.length&&a.substr(0,c.length)===c)return true;return false}function w(a){var c=J(a);if(c.length==0){u();E=x=r=""}else if(c!==r){G();e.jsonp({charset:"UTF-8",dataType:"jsonp",callback:"imdb$"+c,url:"http://sg.media-imdb.com/suggests/"+c.substr(0,1)+"/"+c+".json",error:function(b,d){if(d==="error"&&c.length>1){E=c;v(r,x)?H(c):w(c.substr(0,c.length-1))}},success:function(b){z(b,c);x=c;y=b},pageCache:pageCacheSetting});r=c}}function z(a,
c){if(r===c){var b=c="";if(typeof e("#nb_search").attr("data-hostname")!="undefined")b="http://"+e("#nb_search").attr("data-hostname");for(var d=0;d<a.d.length&&d<S;d+=1){var h=a.d[d],p="suggests-"+d,B="navbar-search",N="see-all-results",l=h.id,O="film-40x54.png",i;if(v(l,"nm")){i=b+"/name/"+l+"/";O="people-40x54.png"}else if(v(l,"tt"))i=b+"/title/"+l+"/";else if(v(l,"http://"))i=l;if(i){l={url:i,title:h.l,detail:h.s,placeholder:O,tag:"navbar-search",slot:p};if(h.i)l.img={url:h.i[0].replace("._V1_.jpg",
"._V1._SX40_CR0,0,40,54_.jpg"),width:40,height:54};if(h.y)l.extra="("+h.y+")";c+=I(l,"navbar-search",p)}}if(c.length>0){G();i=m.val();a=i.replace(D," ");i=jQuery("<div/>").text(i).html();c+='<a class="moreResults" href="';c+=b+"/find?s=all&q="+a+'"';b="";b+="'"+B+"'";b+=",";b+="'"+N+"'";b+=",";b+="this";c+='   onclick="return trackAndClick('+b+');">';c+='<span class="message">See all results for "<span class="query">'+i+'</span>"</span>&nbsp;<span class="raquo">&raquo;</span>';c+="</a>";n.html(c);
n.find("a").hover(function(){o(this)},function(){})}}}function H(a){for(var c=[],b=[],d=0;d<y.d.length;d+=1){var h=y.d[d];J(h.l).match(a)?c.push(h):b.push(h)}z({d:c.concat(b)},a)}function I(a,c,b){var d='<a href="'+a.url+'" class="poster"';d+=" onclick=\"return trackAndClick('"+c+"', '"+b+"', this);\"";d+=">";if(a.img){d+='<img src="'+a.img.url+'"';d+=" style=\"background:url('http://i.media-imdb.com/images/mobile/"+a.placeholder+"')\"";if(a.img.width&&a.img.height)d+=' width="'+a.img.width+'" height="'+
a.img.height+'"';d+=">"}else if(a.placeholder)d+='<img src="http://i.media-imdb.com/images/mobile/'+a.placeholder+'">';d+='<div class="suggestionlabel">';d+='<span class="title">'+a.title+"</span>";if(a.extra)d+=' <span class="extra">'+a.extra+"</span>";if(a.detail)d+='<div class="detail">'+a.detail+"</div>";d+="</div></a>";return d}if(typeof f=="undefined")f={};var m=jQuery(this),n="resultsDiv"in f?f.resultsDiv:jQuery("#autocomplete"),r="",x="",E="",y="",s,S="maxResults"in f?f.maxResults:3,D=/[^\w\u00e0\u00c0\u00e1\u00c1\u00e2\u00c2\u00e3\u00c3\u00e4\u00c4\u00e5\u00c5\u00e6\u00c6\u00e7\u00c7\u00e8\u00c8\u00e9\u00c9\u00ea\u00ca\u00eb\u00cb\u00ec\u00cd\u00ed\u00cd\u00ee\u00ce\u00ef\u00cf\u00f0\u00d0\u00f1\u00d1\u00f2\u00d2\u00f3\u00d3\u00f4\u00d4\u00f5\u00d5\u00f6\u00d6\u00f8\u00d8\u00f9\u00d9\u00fa\u00da\u00fb\u00db\u00fc\u00dc\u00fd\u00dd\u00ff\u00fe\u00de\u00df]/g,
U=/[\u00e0\u00c0\u00e1\u00c1\u00e2\u00c2\u00e3\u00c3\u00e4\u00c4\u00e5\u00c5\u00e6\u00c6\u00e7\u00c7\u00e8\u00c8\u00e9\u00c9\u00ea\u00ca\u00eb\u00cb\u00ec\u00cd\u00ed\u00cd\u00ee\u00ce\u00ef\u00cf\u00f0\u00d0\u00f1\u00d1\u00f2\u00d2\u00f3\u00d3\u00f4\u00d4\u00f5\u00d5\u00f6\u00d6\u00f8\u00d8\u00f9\u00d9\u00fa\u00da\u00fb\u00db\u00fc\u00dc\u00fd\u00dd\u00ff\u00fe\u00de\u00df]/,A="keyboardControl"in f?f.keyboardControl:false;alwaysScrollIntoView="alwaysScrollIntoView"in f?f.alwaysScrollIntoView:true;
pageCacheSetting=e.browser.msie==true?false:true;m.focus(function(){alwaysScrollIntoView&&this.scrollIntoView();if(m.val().length>0){w(m.val());G()}});m.blur(function(){s=setTimeout(u,300)});m.keydown(function(a){if(A)if(a.keyCode==38){m.focus();K();return false}else if(a.keyCode==40){m.focus();Q();return false}else if(a.keyCode==13){C();return false}else if(a.keyCode==27){q();u();return false}m.focus();s=setTimeout(R,0)})};e.fn.stopSearchAutocomplete=function(f){if(typeof f=="undefined")f={};var o=
jQuery(this);f="resultsDiv"in f?f.resultsDiv:jQuery("#autocomplete");o.unbind("focus");o.unbind("blur");o.unbind("keydown");f.css("display","none")}})(jQuery);