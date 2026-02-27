/*!
 *  Howler.js Audio Player Demo
 *  howlerjs.com
 *
 *  (c) 2013-2020, James Simpson of GoldFire Studios
 *  goldfirestudios.com
 *
 *  MIT License
 */

// Кэшируем ссылки на DOM элементы.
var elms = ['track', 'timer', 'duration', 'playBtn', 'pauseBtn', 'prevBtn', 'nextBtn', 'playlistBtn', 'volumeBtn', 'progress', 'barEmpty', 'barFull', 'sliderBtn', 'waveform', 'loading', 'playlist', 'list', 'volume'];
elms.forEach(function (elm) {
  window[elm] = document.getElementById(elm);
});


var xmlhttp = new XMLHttpRequest();
var jsonUrl = "https://player.spongo.ru:443/json/";
var reverse = true;

function directoryToArray(arr) {
  let newFiles = [];
  var i;
  for (i = 0; i < arr.length; i++) {
    if (arr[i].type == "file") {
      newFiles.push({ title: arr[i].name, file: jsonUrl + arr[i].name, howl: null });
    }
  }
  if(reverse) {
    return newFiles.reverse();
  } else {
    return newFiles;
  }
}

var Player = function (playlist) {
  this.playlist = playlist;
  this.index = 0;

  track.innerHTML = '1. ' + playlist[0].title;

  playlist.forEach(function (song) {
    var div = document.createElement('div');
    div.className = 'list-song';
    div.innerHTML = song.title;
    div.onclick = function () {
      player.skipTo(playlist.indexOf(song));
    };
    list.appendChild(div);
  });
};
Player.prototype = {
  play: function (index) {
    var self = this;
    var sound;

    index = typeof index === 'number' ? index : self.index;
    var data = self.playlist[index];

    if (data.howl) {
      sound = data.howl;
    } else {
      sound = data.howl = new Howl({
        src: [data.file],
        html5: true,
        onplay: function () {
          duration.innerHTML = self.formatTime(Math.round(sound.duration()));
          requestAnimationFrame(self.step.bind(self));
          wave.container.style.display = 'block';
          bar.style.display = 'none';
          pauseBtn.style.display = 'block';
        },
        onload: function () {
          wave.container.style.display = 'block';
          bar.style.display = 'none';
          loading.style.display = 'none';
        },
        onend: function () {
          wave.container.style.display = 'none';
          bar.style.display = 'block';
          self.skip('next');
        },
        onpause: function () {
          wave.container.style.display = 'none';
          bar.style.display = 'block';
        },
        onstop: function () {
          wave.container.style.display = 'none';
          bar.style.display = 'block';
        },
        onseek: function () {
          requestAnimationFrame(self.step.bind(self));
        }
      });
    }

    sound.play();

    track.innerHTML = (index + 1) + '. ' + data.title;

    if (sound.state() === 'loaded') {
      playBtn.style.display = 'none';
      pauseBtn.style.display = 'block';
    } else {
      loading.style.display = 'block';
      playBtn.style.display = 'none';
      pauseBtn.style.display = 'none';
    }

    self.index = index;

    if ('mediaSession' in navigator) {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: data.title,
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        artwork: []
      });
      navigator.mediaSession.setActionHandler('play', function() {
        player.play(player.index);
      });
      navigator.mediaSession.setActionHandler('pause', function() {
        player.pause();
      });
      navigator.mediaSession.setActionHandler('previoustrack', function() {
        player.skip('prev');
      });
      navigator.mediaSession.setActionHandler('nexttrack', function() {
        player.skip('next');
      });
      navigator.mediaSession.setActionHandler('seekto', function(details) {
        if (details.fastSeek && 'fastSeek' in player.playlist[player.index].howl) {
          player.playlist[player.index].howl.fastSeek(details.seekTime);
          return;
        }
        player.seek(details.seekTime / player.playlist[player.index].howl.duration());
      });
    }
  },

  pause: function () {
    var self = this;
    var sound = self.playlist[self.index].howl;
    sound.pause();
    playBtn.style.display = 'block';
    pauseBtn.style.display = 'none';
  },

  skip: function (direction) {
    var self = this;
    var index = 0;
    if (direction === 'prev') {
      index = self.index - 1;
      if (index < 0) {
        index = self.playlist.length - 1;
      }
    } else {
      index = self.index + 1;
      if (index >= self.playlist.length) {
        index = 0;
      }
    }
    self.skipTo(index);
  },

  skipTo: function (index) {
    var self = this;
    if (self.playlist[self.index].howl) {
      self.playlist[self.index].howl.stop();
    }
    progress.style.width = '0%';
    self.play(index);
  },

  volume: function (val) {
    var self = this;
    Howler.volume(val);
    var barWidth = (val * 90) / 100;
    barFull.style.width = (barWidth * 100) + '%';
    sliderBtn.style.left = (window.innerWidth * barWidth + window.innerWidth * 0.05 - 25) + 'px';
  },

  seek: function (per) {
    var self = this;
    var sound = self.playlist[self.index].howl;
    if (sound.playing()) {
      sound.seek(sound.duration() * per);
    }
  },

  step: function () {
    var self = this;
    var sound = self.playlist[self.index].howl;
    var seek = sound.seek() || 0;
    timer.innerHTML = self.formatTime(Math.round(seek));
    if (!isSeeking) {
      progress.style.width = (((seek / sound.duration()) * 100) || 0) + '%';
      var startX = barEmpty.getBoundingClientRect().left;
      var width = barEmpty.offsetWidth;
      var sliderPos = startX + (seek / sound.duration()) * width;
      sliderBtn.style.left = sliderPos + 'px';
    }
    if (sound.playing()) {
      requestAnimationFrame(self.step.bind(self));
    }
  },

  togglePlaylist: function () {
    var self = this;
    var display = (playlist.style.display === 'block') ? 'none' : 'block';
    setTimeout(function () {
      playlist.style.display = display;
    }, (display === 'block') ? 0 : 500);
    playlist.className = (display === 'block') ? 'fadein' : 'fadeout';
  },

  toggleVolume: function () {
    var self = this;
    var display = (volume.style.display === 'block') ? 'none' : 'block';
    setTimeout(function () {
      volume.style.display = display;
    }, (display === 'block') ? 0 : 500);
    volume.className = (display === 'block') ? 'fadein' : 'fadeout';
  },

  formatTime: function (secs) {
    var minutes = Math.floor(secs / 60) || 0;
    var seconds = (secs - minutes * 60) || 0;
    return minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
  }
};

var player;

var isSeeking = false;

function testos() {
  xmlhttp.onreadystatechange = function () {
    if (this.readyState == 4 && this.status == 200) {
      myArr = JSON.parse(this.responseText);
      player = new Player(directoryToArray(myArr));

      playBtn.addEventListener('click', function () {
        player.play();
      });
      pauseBtn.addEventListener('click', function () {
        player.pause();
      });
      prevBtn.addEventListener('click', function () {
        player.skip('prev');
      });
      nextBtn.addEventListener('click', function () {
        player.skip('next');
      });
      waveform.addEventListener('click', function (event) {
        player.seek(event.clientX / window.innerWidth);
      });
      playlistBtn.addEventListener('click', function () {
        player.togglePlaylist();
      });
      playlist.addEventListener('click', function () {
        player.togglePlaylist();
      });
      volumeBtn.addEventListener('click', function () {
        player.toggleVolume();
      });
      volume.addEventListener('click', function () {
        player.toggleVolume();
      });

      // Volume slider handlers
      barEmpty.addEventListener('click', function (event) {
        var per = event.layerX / parseFloat(barEmpty.scrollWidth);
        player.volume(per);
      });

      sliderBtn.addEventListener('mousedown', function () {
        isSeeking = true;
      });
      sliderBtn.addEventListener('touchstart', function () {
        isSeeking = true;
      });
      window.addEventListener('mouseup', function () {
        if (isSeeking) {
          isSeeking = false;
        }
      });
      window.addEventListener('touchend', function () {
        if (isSeeking) {
          isSeeking = false;
        }
      });
      window.addEventListener('mousemove', function (event) {
        if (isSeeking) {
          updateSeek(event.clientX);
        }
      });
      window.addEventListener('touchmove', function (event) {
        if (isSeeking) {
          updateSeek(event.touches[0].clientX);
        }
      });

      wave.start();
      resize();
    }
  };
  xmlhttp.open("GET", jsonUrl, true);
  xmlhttp.send();
}

function updateSeek(x) {
  var startX = barEmpty.getBoundingClientRect().left;
  var width = barEmpty.offsetWidth;
  var clampX = Math.min(Math.max(x, startX), startX + width);
  var percent = (clampX - startX) / width;

  progress.style.width = (percent * 100) + '%';
  sliderBtn.style.left = clampX + 'px';

  if (player && player.playlist[player.index].howl) {
    player.seek(percent);
  }
}

var wave = new SiriWave({
  container: waveform,
  width: window.innerWidth,
  height: window.innerHeight * 0.3,
  cover: true,
  speed: 0.03,
  amplitude: 0.7,
  frequency: 2
});

var move = function (event) {
  if (window.sliderDown) {
    var x = event.clientX || event.touches[0].clientX;
    var startX = window.innerWidth * 0.05;
    var layerX = x - startX;
    var per = Math.min(1, Math.max(0, layerX / parseFloat(barEmpty.scrollWidth)));
    player.volume(per);
  }
};

var resize = function () {
  var height = window.innerHeight * 0.3;
  var width = window.innerWidth;
  wave.height = height;
  wave.height_2 = height / 2;
  wave.MAX = wave.height_2 - 4;
  wave.width = width;
  wave.width_2 = width / 2;
  wave.width_4 = width / 4;
  wave.canvas.height = height;
  wave.canvas.width = width;
  wave.container.style.margin = -(height / 2) + 'px auto';

  var sound = player && player.playlist[player.index].howl;
  if (sound) {
    var vol = sound.volume();
    var barWidth = (vol * 0.9);
    sliderBtn.style.left = (window.innerWidth * barWidth + window.innerWidth * 0.05 - 25) + 'px';
  }
};

window.addEventListener('resize', resize);
testos();
