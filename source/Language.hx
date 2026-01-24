/* This class has language variables in it, used for Türkiye editor of Psych Extended Online */

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
		"Playing a online private game!"	 => "Online Özel Maçta",
		"Story Mode: "	 => "Hikaye Modu: ",
		"'s Replay"	 => "'nin Replay'i",
		"Paused - "	 => "Durduruldu - ",
		"TOUCH YOUR SCREEN TO START"	 => "BAŞLAMAK IÇIN EKRANA TIKLA",
		"PRESS ACCEPT TO START"	 => "BAŞLAMAK IÇIN ACCEPT'A BASIN",

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
		"Retry No. "            => "Deneme Sayısı: "
		
		// Gameplay Ayarları
		"Mania"                     => "Tuş Sayısı",
		"Scroll Type"               => "Kaydırma Türü",
		"Scroll Speed"              => "Kaydırma Hızı",
		"Scroll Speed By Mania"     => "Tuş Sayısına Göre Hız",
		"Playback Rate"             => "Oynatma Hızı",
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
		"FUNK THEIR BRAINS OUT BOYFRIEND" => "SAMETI SIK BOYFRIEND",
		
		// Menü ve Leaderboard Başlıkları
		"GAMEPLAY MODIFIERS"      => "OYNANIŞ MODİFİKATÖRLERİ",
		"MODIFIERS UNAVAILABLE HERE" => "MODİFİKATÖRLER BURADA KULLANILAMAZ",
		"LOAD REPLAY"             => "TEKRARI YÜKLE",
		"REPLAYS UNAVAILABLE"     => "TEKRARLAR KULLANILAMAZ",
		"RESET SCORE"             => "SKORU SIFIRLA",
		"LEADERBOARD"             => "LİDERLİK TABLOSU",
		"LOADING"                 => "YÜKLENİYOR",
		"FlashingState.warnText"  => "Hey, dikkat et!\n
			Bu Mod bazı yanıp sönen ışıklar içeriyor!\n
			Flaşları kapatmak veya Ayarlar'a gitmek için %{1}% tuşuna bas.\n
			Bu mesajı görmezden gelmek için %{2}% tuşuna bas.\n
			Uyarıldın!",

		//Hardcoded Zorluklar
		"HARD" => "ZOR",
		"EASY" => "KOLAY",

	];
	//normal texts will go there when turkish version done
	public static var normalTexts:Map<String, String> = [
		"FlashingState.warnText" => "Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press %{1}% to disable them now or go to Options Menu.\n
			Press %{2}% to ignore this message.\n
			You've been warned!"
	]
	public static inline function getText(ogText:String, ?args:Array<String>):String {
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
				text = StringTools.replace(text, placeholder, args[i]);
			}
		}

		return text;
	}
}