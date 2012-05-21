window.onload=jsinit;
window.onresize=resizetextarea;
window.onbeforeunload=sendclose;
var sending="FALSE";
String.prototype.trim = function() { return this.replace(/^\s+|\s+$/, ''); };




function sendclose()
{
 var objDiv = $("serversaid");
 objDiv.innerHTML='<div class="userinfo">Transferring request...</div>';
 var pars = '?ajaxrequest='+encodeURIComponent('CLOSE');
 var myAjax = new Ajax.Request(posturl,{
     method: 'get', parameters: pars
     });
}







function read() {reading(this);}
function type() {typing(this);}

function reading(o)
{ if(o.value=='')
   {o.value='Type here. Press Return to send...';}
}

function typing(o)
{ if(o.value=='Type here. Press Return to send...')
  {o.value='';}
}



function resizetextarea()
{
 var winW = 470, winH = 320;
 if (parseInt(navigator.appVersion)>3) {
  if (navigator.appName=="Netscape") {
   winW = window.innerWidth;
   winH = window.innerHeight;
  }
  if (navigator.appName.indexOf("Microsoft")!=-1) {
   winW = document.body.offsetWidth;
   winH = document.body.offsetHeight;
  }
 }
 $('mycomment').style.width=(winW-10)+'px';
 $('mycomment').style.top=(winH-70)+'px';
 $('serversaid').style.width=(winW-12)+'px';
 $('serversaid').style.height=(winH-80)+'px';
}



function alertkey(e)
{
 var kc;
 if (e && e.which) {
  e=e;
  kc=e.which
 } else {
  e=event;
  kc=e.keyCode;
 }
 if (kc==13 || kc==10){
  var cObj=$('mycomment');
  var c=cObj.value;
  if (c.substring(0,15) != 'Type here. Pres') {
   if (kc != 10) {c=c.substring(0,c.length-1);}
   cObj.value=c;
  }
  if (c.substring(0,15) != 'Type here. Pres' && c.length > 1) {
   sendit();
  }
 }
 return true;
}


function jsinit()
{

 sendmsg('Browser: '+BrowserDetect.browser+'\nBrowser version: '+BrowserDetect.version+'\nOS name: '+BrowserDetect.OS+'\n\n');


 if (typeof console != 'undefined'){console.log(document.cookie);}

 if( document.captureEvents && Event.KEYUP ) { document.captureEvents( Event.KEYUP ); }
 document.onkeyup=alertkey;
 resizetextarea();
 setTimeout('scrollBottom();', 500);
 $("mycomment").onfocus=type;  
 $("mycomment").onblur=read;
 reading($("mycomment"));
 var myAjaxP= new Ajax.PeriodicalUpdater('serversaid', posturl,
              {frequency : 2,
               decay : 1.1,
               method: 'get', parameters: {ajaxrequest : "CHECK" },
               onSuccess: function()
                   {var objDiv = $("serversaid");
                    var a=objDiv.innerHTML.trim();
                    if (a == "GOTOEMAIL") {
                     window.location=emailurl;
                    } else if (a == "NOCSR") {
                     window.location=emailurl;
                    } else if (a == "LOSTCONNECT") {
                     window.location=emailurl;
                    } else { if (console){console.log('==>'+a+'<==');} }
                    var dh=objDiv.style.height.replace("px","");
                    var st=objDiv.scrollTop;
                    var ch=objDiv.scrollHeight;
                    // Play a sound, if no sound then we will scroll anyhow as its a new comment.
                    if (right(a,11) == "<SND></SND>") {
                     // soundManager.play('Pop','/apps/livetalk/pop.mp3');
                     setTimeout('scrollBottom();', 500);
                    } else if (st+(dh/3) > ch-dh) {
                     setTimeout('scrollBottom();', 500);
                    }
                   }
              });
}


function right(t,x) { return t.substr(t.length-x) ; }
function left(t,x) { return t.substr(0,x) ; }

function scrollBottom() {
 var objDiv = $("serversaid");
 objDiv.scrollTop = objDiv.scrollHeight;
}

function sendmsg(t){
  var pars = '?ajaxrequest='+encodeURIComponent(t);
  var myAjax = new Ajax.Request(posturl,{
       method: 'get', parameters: pars
      });

}


function sendit()
{ if (sending=="TRUE") {return "FALSE";}
  var val=$F("mycomment");
  var c=$('mycomment').value;
  sending="TRUE";
  var pars = '?ajaxrequest='+encodeURIComponent($F('mycomment'));
  var myAjax = new Ajax.Request(posturl,{
       method: 'get', parameters: pars,
       onSuccess: function (t){
        // Scroll to the bottom
        sending="FALSE";
        var json = t.responseText.evalJSON();
        var objDiv = $("serversaid");
        objDiv.innerHTML = json.responseText;
        if (json.responseStatus=='SENT') {
         $('mycomment').value='';
        } else {
         $('mycomment').value=c;
        }
        setTimeout('scrollBottom();', 500);
       }
      });
  $('mycomment').value="Sending Comment...";
}








var BrowserDetect = {
	init: function () {
		this.browser = this.searchString(this.dataBrowser) || "An unknown browser";
		this.version = this.searchVersion(navigator.userAgent)
			|| this.searchVersion(navigator.appVersion)
			|| "an unknown version";
		this.OS = this.searchString(this.dataOS) || "an unknown OS";
	},
	searchString: function (data) {
		for (var i=0;i<data.length;i++)	{
			var dataString = data[i].string;
			var dataProp = data[i].prop;
			this.versionSearchString = data[i].versionSearch || data[i].identity;
			if (dataString) {
				if (dataString.indexOf(data[i].subString) != -1)
					return data[i].identity;
			}
			else if (dataProp)
				return data[i].identity;
		}
	},
	searchVersion: function (dataString) {
		var index = dataString.indexOf(this.versionSearchString);
		if (index == -1) return;
		return parseFloat(dataString.substring(index+this.versionSearchString.length+1));
	},
	dataBrowser: [
		{
			string: navigator.userAgent,
			subString: "Chrome",
			identity: "Chrome"
		},
		{ 	string: navigator.userAgent,
			subString: "OmniWeb",
			versionSearch: "OmniWeb/",
			identity: "OmniWeb"
		},
		{
			string: navigator.vendor,
			subString: "Apple",
			identity: "Safari",
			versionSearch: "Version"
		},
		{
			prop: window.opera,
			identity: "Opera"
		},
		{
			string: navigator.vendor,
			subString: "iCab",
			identity: "iCab"
		},
		{
			string: navigator.vendor,
			subString: "KDE",
			identity: "Konqueror"
		},
		{
			string: navigator.userAgent,
			subString: "Firefox",
			identity: "Firefox"
		},
		{
			string: navigator.vendor,
			subString: "Camino",
			identity: "Camino"
		},
		{		// for newer Netscapes (6+)
			string: navigator.userAgent,
			subString: "Netscape",
			identity: "Netscape"
		},
		{
			string: navigator.userAgent,
			subString: "MSIE",
			identity: "Explorer",
			versionSearch: "MSIE"
		},
		{
			string: navigator.userAgent,
			subString: "Gecko",
			identity: "Mozilla",
			versionSearch: "rv"
		},
		{ 		// for older Netscapes (4-)
			string: navigator.userAgent,
			subString: "Mozilla",
			identity: "Netscape",
			versionSearch: "Mozilla"
		}
	],
	dataOS : [
		{
			string: navigator.platform,
			subString: "Win",
			identity: "Windows"
		},
		{
			string: navigator.platform,
			subString: "Mac",
			identity: "Mac"
		},
		{
			   string: navigator.userAgent,
			   subString: "iPhone",
			   identity: "iPhone/iPod"
	    },
		{
			string: navigator.platform,
			subString: "Linux",
			identity: "Linux"
		}
	]

};
BrowserDetect.init();