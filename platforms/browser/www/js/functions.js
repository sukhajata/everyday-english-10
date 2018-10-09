function speak(txt) {
	
	TTS.speak({
            text: txt,
            locale: 'en-US',
            rate: 0.7
        }, function () {
            //alert('success');
        }, function (reason) {
            //alert(reason);
        });
	
}

function speakButton(text, button) {
	var highlighted = document.getElementsByClassName("frame-highlight");
	if( highlighted.length > 0) {
		highlighted[0].className = "frame";
	}
	button.parentElement.className = "frame-highlight";
	speak(text);
	
}

function logout() {
	localStorage.removeItem('userId');
	window.location = "index.html";
	return false;
}

function GetURLParameter(sParam) {
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++) 
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam) 
        {
            return sParameterName[1];
        }
    }
}

function openNav() {
    document.getElementById("sidenav").style.width = "250px";
}

function closeNav() {
    document.getElementById("sidenav").style.width = "0";
}

function openSong(id) {
    window.location = "song.html?lessonId=" + id;
}

function showSongs() {
    $('#songpanel').toggle();
    
    return false;
}

function shuffle(a) {
    var j, x, i;
    for (i = a.length - 1; i > 0; i--) {
        j = Math.floor(Math.random() * (i + 1));
        x = a[i];
        a[i] = a[j];
        a[j] = x;
    }
    return a;
}

function escape_quotes(str) {
    return str.replace(/\'/g,"\\'");
}