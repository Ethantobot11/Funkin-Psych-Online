/* This class has language variables in it, used for Türkiye edition of Psych Extended Online */

class Language {
	public static var turkishTexts:Map<String, String> = [
		// Ratingler
		"You Suck!"	 => "Çok Kötü!",
		"Shit"		  => "Berbat!",
		"Bad"		   => "Kötü",
		"Bruh"		  => "Eh işte...",
		"Meh"		   => "İdare eder",
		"Nice"		  => "İyi",
		"Good"		  => "Güzel",
		"Great"		 => "Harika",
		"Sick!"		 => "Müthiş!",
		"Perfect!!"	 => "Mükemmel!",

		// Online Elemanları
		"In-Game"	 => "Oyunda",
		"Playing a online game!"	 => "Online Maçta",
		"Playing a online private game!"	 => "Özel Online Maçta",
		"Story Mode: "	 => "Hikaye Modu: ",
		"'s Replay"	 => "'nin Replay'i",
		"Paused - "	 => "Durduruldu - ",
		"TOUCH YOUR SCREEN TO START"	 => "BAŞLAMAK İÇİN EKRANA TIKLAYIN 1",
		"PRESS ACCEPT TO START"	 => "BAŞLAMAK İÇİN ACCEPT'A BASIN",

		// Pause Menüsü Elemanları
		"Resume"                => "Devam Et",
		"Restart Song"          => "Şarkıyı Yeniden Başlat",
		"Change Difficulty"     => "Zorluğu Değiştir",
		"Leave Charting Mode"   => "Charting Modundan Çık",
		"Skip Time"             => "Zamana Atla",
		"End Song"              => "Şarkıyı Bitir",
		"Toggle Practice Mode"  => "Pratik Modunu Aç/Kapat",
		"Toggle Botplay"        => "Bot Oynanışını Aç/Kapat",
		"Options"               => "Ayarlar",
		"Exit to menu"          => "Ana Menüye Dön",
		"Exit to lobby"         => "Lobiye Dön",
		"Post a Comment Now"    => "Şimdi Yorum Yaz",
		"Debug Tools"           => "Hata Ayıklama Araçları",
		"Save Replay"           => "Tekrarı Kaydet",
		"Report Replay"         => "Tekrarı Raporla",
		"Back"                  => "Geri",

		// Debug / Gelişmiş Araçlar
		"Playback Rate"         => "Oynatma Hızı",
		"Run Script"            => "Script Çalıştır",
		"Swap Sides"            => "Tarafları Değiştir",
		"Chart Editor"          => "Chart Editörü",
		"Character Editor"      => "Karakter Editörü",
		"Position Debug"        => "Pozisyon Hata Ayıklama",
		"Swing Mode"            => "Sallanma Modu",
		"Charting Mode"         => "Charting Modu",
		"Stage 3D Debug"        => "3D Sahne Hata Ayıklama",

		// Diğer Ekran Yazıları (Pause Menüsü içindeki küçük metinler)
		"PRACTICE MODE"         => "PRATİK MODU",
		"CHARTING MODE"         => "CHARTING MODU",
		"Retry No. "            => "Deneme Sayısı: ",
		
		// Gameplay Ayarları
		"Mania"                     => "Tuş Sayısı",
		"Scroll Type"               => "Kaydırma Türü",
		"Scroll Speed"              => "Kaydırma Hızı",
		"Scroll Speed By Mania"     => "Tuş Sayısına Göre Hız",
		"HP Gain Multiplier"        => "Can Kazanma Çarpanı",
		"HP Loss Multiplier"        => "Can Kaybetme Çarpanı",
		"Botplay"                   => "Bot Oynanışı",
		"Instakill on Miss"         => "Kaçırınca Direkt Geber",
		"Practice Mode"             => "Pratik Modu",
		"Play as Opponent"          => "Rakip Olarak Oyna",
		"No Hurt Notes"             => "Hasar Veren Notaları Sil",
	
		//Reset Score SubState
		"Reset the score of"             => "Belirlenen Şarkının Scorunu Sıfırlamak Istiyormusunuz?:",
		"Yes"		=> "Evet",
		"No"		=> "Hayır",
		
		// Freeplay'deki motivasyon cümleleri
		"PROTECT YO NUTS BOYFRIEND"       => "SOMUNLARINI KORU BOYFRIEND",
		"DON'T STOP BOYFRIEND"            => "DURMA BOYFRIEND",
		"FUNK 'EM UP BOYFRIEND"           => "GÖSTER GÜNÜNÜ BOYFRIEND",
		"GO FOR A 100% BOYFRIEND"         => "HEDEF %100 BOYFRIEND",
		"GO WITH THE RHYTHM BOYFRIEND"    => "RİTME AYAK UYDUR BOYFRIEND",
		"STAY FUNKY BOYFRIEND"            => "HAVANI KORU BOYFRIEND",
		"GET LAID BOYFRIEND"              => "ŞANSINI DENE BOYFRIEND",
		"DON'T KNOCK UP BOYFRIEND"        => "ÇUVALLAMA BOYFRIEND",
		"BEHIND YOU BOYFRIEND"            => "ARKANDAYIM BOYFRIEND",
		"DRINK PISS BOYFRIEND"            => "GİT Bİ' ÇAY İÇ BOYFRIEND",
		"COME TO BRAZIL BOYFRIEND"        => "BAĞCILARA GEL BOYFRIEND",
		"FUNK THEIR BRAINS OUT BOYFRIEND" => "SAMETİ SİK BOYFRIEND",
		
		// Menü ve Leaderboard Başlıkları
		"GAMEPLAY MODIFIERS"      => "OYNANIŞ MODiFiKASYONLARI",
		"MODIFIERS UNAVAILABLE HERE" => "MODiFiKASYONLAR BURADA KULLANILAMAZ",
		"LOAD REPLAY"             => "TEKRARI YÜKLE",
		"REPLAYS UNAVAILABLE"     => "TEKRARLAR KULLANILAMAZ",
		"RESET SCORE"             => "SKORU SIFIRLA",
		"LEADERBOARD"             => "LiDERLiK TABLOSU",
		"LOADING"                 => "YÜKLENiYOR",
		"FlashingState.warnText"  => "Hey, dikkat et!\n
			Bu Mod bazı yanıp sönen ışıklar içeriyor!\n
			Flaşları kapatmak veya Ayarlar'a gitmek için %{1}% tuşuna bas.\n
			Bu mesajı görmezden gelmek için %{2}% tuşuna bas.\n
			Uyarıldın!",

		//Hardcoded Zorluklar
		"NIGHTMARE" => "KABUS",
		"HARD" => "ZOR",
		"EASY" => "KOLAY",

		//Ayarlar
		"Note Colors" => "Nota Renkleri",
		"Controls" => "Kontroller",
		"Adjust Delay and Combo" => "Gecikme ve Kombo",
		"Graphics" => "Grafikler",
		"Visuals" => "Görseller",
		"Gameplay" => "Oynanış",
		"Mobile" => "Mobil",

		//Mobil Ayarlar
		"MobilePad Opacity" => "MobilePad Opaklığı",
		"Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons)." => "Mobil düğmelerin opaklığını seçer (0 olarak ayarlayıp düğmelerinizi kaybetmeyin).",
		"Extra Controls" => "Ektra Kontroller",
		"Allow Extra Controls" => "Kaç tane ektra kontrol ekleneyeceğini seçiniz",
		"Hitbox Mode" => "Hitbox Modu",
		"Choose your Hitbox Style!" => "Hitbox stilini seç!",
		"Hitbox Design" => "Hitbox Şekli/Dizaynı",
		"Choose how your hitbox should look like." => "Hitbox'ın nasıl görünmeli.",

		//Score Text
		"PlayState.updateTeamSide.daText" => "%{1}%
			\nSkor: %{2}%
			\nIskalar: %{3}%
			\nDoğruluk: %{4}%%" + (ClientPrefs.data.showFP ? '\nFP: %{5}%' : '') + "\nGecikme: %{6}%ms",

		"PlayState.updateScoreSID.if (countSide > 1).daText" => 
			'%{1}%: %{2}% | %{3}% M | %{4}%% - %{5}%' + (ClientPrefs.data.showFP ? ' | %{6}%FP' : '') + ' | %{7}%ms',

		"PlayState.updateScoreSID.else.daText" => '%{1}%\nSkor: %{2}%\nIskalar: %{3}%\nRating: %{4}%' + (ClientPrefs.data.showFP ? '\nFP: %{5}%' : '') + "\nGecikme: %{6}%",
		"PlayState.updateScore.scoreTextObject" => "Skor: %{1}% | Iskalar: %{2}% | Rating: %{3}%",
	];
	//normal texts will go there when turkish version done
	public static var normalTexts:Map<String, String> = [
		"FlashingState.warnText" => "Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press %{1}% to disable them now or go to Options Menu.\n
			Press %{2}% to ignore this message.\n
			You've been warned!",

		"PlayState.updateTeamSide.daText" => "%{1}%
			\nScore: %{2}%
			\nMisses: %{3}%
			\nAccuracy: %{4}%%" + (ClientPrefs.data.showFP ? '\nFP: %{5}%' : '') + "\nPing: %{6}%ms",

		"PlayState.updateScoreSID.if (countSide > 1).daText" => 
			'%{1}%: %{2}% | %{3}% M | %{4}%% - %{5}%' + (ClientPrefs.data.showFP ? ' | %{6}%FP' : '') + ' | %{7}%ms',

		"PlayState.updateScoreSID.else.daText" => '%{1}%\nScore: %{2}%\nMisses: %{3}%\nRating: %{4}%' + (ClientPrefs.data.showFP ? '\nFP: %{5}%' : '') + "\nPing: %{6}%",
		"PlayState.updateScore.scoreTextObject" => "Score: %{1}% | Misses: %{2}% | Rating: %{3}%"
	];
	public static inline function getText(ogText:String, ?args:Array<Dynamic>):String {
		var text:String = ogText;

		#if TURKIYE_BUILD
		if (turkishTexts.exists(text))
			text = turkishTexts.get(text);
		#else
		if (normalTexts.exists(text))
			text = normalTexts.get(text);
		#end

		if (args != null && args.length > 0) {
			for (i in 0...args.length) {
				var placeholder:String = "%{" + (i + 1) + "}%";
				args[i] = Std.string(args[i]);
				text = StringTools.replace(text, placeholder, args[i]);
			}
		}

		return text;
	}
}