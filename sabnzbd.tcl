# SCRIPT INFORMATION
# This script allows users to check the status of their SABnzbd
# in the specified IRC channels.
#
# Currently there are 8 commands (4 can be done by anyone, 4 require you to be set in the config):
# ANYONE
# !sabnzbd stats - Gives a quick breakdown current status"
# !sabnzbd queue [n] - Shows current items in queue. Default is 3. Specify n to show more or less
# !sabnzbd version - Shows current version of SABnzbd and also this script
# !sabnzbd help - Shows usage information
#
# !nzbindex search [-n<number of items to return>] [-mi<minimum MB>] [-ma<maximum MB>]  <search terms>
# 	Searches NZBIndex and returns results. Default is 3 results. 
#	Specify -n10 to show 10 results. 
#	Specify -mi100 to only show releases that are at last 100MB.
#	Specify -ma1000 to only show releases that are smaller than 1000MB
#
# !tvbinz search [-n<number of items to return>] <search terms> - Searches TVBINZ and returns results. Default is 3 results. Specify -n10 to show 10 results
#
# !binsearch search [-n<number of items to return>] <search terms> - Searches Binsearch and returns results. Default is 3 results. Specify -n10 to show 10 results.
#
# !newzleech search [-n<number of items to return>] <search terms> - Searches Newzbin and returns results. Default is 3 results. Specify -n10 to show 10 results.
# ADMIN
# !sabnzbd add <URL/Newzbin ID> - Adds a URL or Newzbin ID to SABnzbd
# !sabnzbd speed <Speed in KB/s (0 to remove limit)> - Sets the speedlimit in SABnzbd
# !sabnzbd pause - Pauses SABnzbd
# !sabnzbd resume - Resumes SABnzbd
# !nzbindex add <NZBIndex ID> - Adds the specified ID to SABnzbd. The ID is returned by the search results
#
# !tvbinz add <TVBINZ ID> - Adds the specified ID to SABnzbd. The ID is returned by the search results
#
# !binsearch add [-n<NZB Name>] <Binsearch IDs> - Adds the specified IDs to SABnzbd (you can specify more than 1 ID, seperate with spaces).
#	Specify -nExampleNZBName to specify the name of the NZB being sent to SAB, if not set Binsearch will determine
#
# !newzleech add [-n<NZB Name>] <Newzleech IDs> - Adds the specified IDs to SABnzbd (you can specify more than 1 ID, seperate with spaces). 
#	Specify -nExampleNZBName to specify the name of the NZB being sent to SAB, if not set Newzleech will determine it
#
# This is the first ever TCL script I have written so if you have any
# suggestions as too how it can be improved or find any bugs contact me on
# Efnet nick: dr0pknutz
#
# REQUIREMENTS:
#
# TCL HTTP package is required.
# tDOM - Can be found here http://www.tdom.org/#SECTid0x80bd158
# zlib - Is only required if you want TVBINZ support. Available here: http://pascal.scheffers.net/software/zlib-1.1.1.tar.bz2
#
# VERSIONS:
#
# v0.1 - Initial release
# v0.2 - Added add/pause/resume/version/speed/help.
# v0.3 - Added the ability to search TVBINZ.NET and NZBIndex.nl and add NZBs from there.
# v0.4 - Added the ability to search Binsearch.info and add NZBs from there.
# v0.5 - Added the ability to search Newzleech.com and add NZBs from there.
# v0.5.1 - Added support for API key (pepzi)

package require http
package require tdom

# CONFIGURATION
# Set your SABnzbd username here, if you don't use one set to ""
set sabnzbd(username) "osmosis"
# Set your SABnzbd password here, if you don't use one set to ""
set sabnzbd(password) "Mjw9kk33"
# Set you SABnzbd API key here
set sabnzbd(key) "30950982dd80abb4d97cc03e3949c7f1"
# Set the host that SABnzbd runs on.
set sabnzbd(host) "24.67.149.106"
# Set the port that SABnzbd runs on.
set sabnzbd(port) "8080"
# Set the channels that the script should respond on.
set sabnzbd(chans) "#shellco.de #enigma"
# Set the nicks that can add/pause/resume/speed.
set sabnzbd(nicks) "Osmosis"
# Set whether or not you want to enable TVBINZ.net support
# WARNING: THIS REQUIRES ZLIB SO MAKE SURE YOU HAVE IT INSTALLED BEFORE USING IT!
set sabnzbd(tvbinz) "true"
# Set whether or not you want to enable NZBIndex.nl supports
set sabnzbd(nzbindex) "true"
# Set whether or not you want to enable Binsearch.info supports
set sabnzbd(binsearch) "true"
# Set whether or not you want to enable Newzleech.com supports
set sabnzbd(newzleech) "true"
# END CONFIGURATION

bind pub - !sabnzbd sabnzbdTrigger

if {$sabnzbd(tvbinz) == "true"} {
#	package require zlib
	bind pub - !tvbinz tvbinzTrigger
}
if {$sabnzbd(nzbindex) == "true"} {
	bind pub - !nzbindex nzbindexTrigger
}
if {$sabnzbd(binsearch) == "true"} {
	bind pub - !binsearch binsearchTrigger
}
if {$sabnzbd(binsearch) == "true"} {
	bind pub - !newzleech newzleechTrigger
}
set sabnzbd(version) "0.5.1"

proc sabnzbdTrigger { nick host hand chan arg } {
	global sabnzbd
	set sabUserPass ""
	if {($sabnzbd(username) != "") && ($sabnzbd(password) != "")} {
		set sabUserPass "&ma_username=$sabnzbd(username)&ma_password=$sabnzbd(password)"
	}
	if {([lsearch -exact $sabnzbd(chans) $chan] == -1)} { return }    
	set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=qstatus&output=xml$sabUserPass&apikey=$sabnzbd(key)"

	if {($arg == "stats")} {
		set queueStatus [http::data [http::geturl $url]]
		set doc [dom parse $queueStatus]
		set root [$doc documentElement]
		set paused [[$root selectNodes /queue/paused/text()] data]
		if {$paused == "True"} {
			set speed "Paused"
		} else {
			set speed "[format "%.2f" [[$root selectNodes /queue/kbpersec/text()] data]]KB/s"
		}
		set mb [format "%.2f" [[$root selectNodes /queue/mb/text()] data]]
		set mbleft [format "%.2f" [[$root selectNodes /queue/mbleft/text()] data]]
		set noinq [[$root selectNodes /queue/noofslots/text()] data]
		set time [[$root selectNodes /queue/timeleft/text()] data]
		set jobs [llength [$root selectNodes /queue/jobs/job]]
		if {($jobs != 0)} {
			set firstJobNode [lindex [$root selectNodes /queue/jobs/job] 0]
			set curFileName [[$firstJobNode selectNodes filename/text()] data]
			set curMb [format "%.2f" [[$firstJobNode selectNodes mb/text()] data]]
			set curMbLeft [format "%.2f" [[$firstJobNode selectNodes mbleft/text()] data]]
			set curMbDone [format "%.2f" [expr $curMb - $curMbLeft]]
			set curPercent [format "%.2f" [expr [expr $curMbDone / $curMb] * 100]]
			set currentJob "$curFileName (${curMbDone}MB/${curMb}MB) (${curPercent}%)"
		} else {
			set currentJob "Nothing In Queue"
		}
		putserv "PRIVMSG $chan :\002\[SABnzbd Stats\]\002 Speed:\002\[$speed\]\002 Queue Status:\002\[${mbleft}MB/${mb}MB($noinq items)\]\002 Time Remaining:\002\[$time\]\002 Current Job:\002\[$currentJob\]\002"
	} elseif {([lindex $arg 0] == "queue")} {
		set queueStatus [http::data [http::geturl $url]]
		set doc [dom parse $queueStatus]
		set root [$doc documentElement]
		set jobs [$root selectNodes /queue/jobs/job]
		if {([lindex $arg 1] != "") && ([string is integer -strict [lindex $arg 1]])} { 
			set noDisplay [lindex $arg 1] 
			if [expr [lindex $arg 1] > 10] { set noDisplay 10 }
		} else {
			set noDisplay 3
	    }
		if {([llength $jobs] != 0)} {
			if {([llength $jobs] < $noDisplay)} { 
				set showing [llength $jobs]
			} else { set showing $noDisplay }
			set mb [format "%.2f" [[$root selectNodes /queue/mb/text()] data]]
			set mbleft [format "%.2f" [[$root selectNodes /queue/mbleft/text()] data]]
			set noinq [[$root selectNodes /queue/noofslots/text()] data]
			putserv "PRIVMSG $chan :\002\[SABnzbd Queue\]\002 Queue Status:\002\[${mbleft}MB/${mb}MB($noinq items)\]\002 Displaying:\002\[$showing\]\002"
			foreach x $jobs {
				incr item
				set fname [[$x selectNodes filename/text()] data]
				set mb [format "%.2f" [[$x selectNodes mb/text()] data]]
				set mbleft [format "%.2f" [[$x selectNodes mbleft/text()] data]]
				putserv "PRIVMSG $chan :\002\[Queue Item #$item\]\002 File:\002\[$fname\]\002 Remaining:\002\[${mbleft} MB/${mb} MB\]\002"
				if {($item >= $noDisplay)} { return }
			}
		} else {
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 No Items In Queue"
		}		
    } elseif {([lindex $arg 0] == "add")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot add an NZB"
			return
		}   
		if {([llength $arg] <= 1)} {
			putserv "NOTICE $nick :Usage: !sabnzbd add <URL/Newzbin ID>"
		} else {		
			if {([string is integer -strict [lindex $arg 1]])} {
				set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=addid&name=[lindex $arg 1]$sabUserPass&apikey=$sabnzbd(key)"
				set returnMess [http::data [http::geturl $url]]
			} else {
				if {![regexp {^http://.+} [lindex $arg 1]]} { 
					putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Not a valid URL. Must be: http://example.com/example.nzb"
					return
				}
				set urlEncode [http::formatQuery mode addurl name [lindex $arg 1] ma_username $sabnzbd(username) ma_password $sabnzbd(password) apikey $sabnzbd(key)]
				set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?"
				set returnMess [http::data [http::geturl $url -query $urlEncode]]
			}
			if { [string compare $returnMess "ok"] != 0 } {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item added successfully"
			} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item not added" 
			}
		}
	} elseif {([lindex $arg 0] == "pause")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot pause SABnzbd"
			return
		}   
		set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=pause$sabUserPass&apikey=sabnzbd(key)"
		set returnMess [http::data [http::geturl $url]]
		if { [string compare $returnMess "ok"] != 0 } {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Is now paused"
		} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Was not paused for some reason" 
		}
	} elseif {([lindex $arg 0] == "resume")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot resume SABnzbd"
			return
		}   
		set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=resume$sabUserPass&apikey=$sabnzbd(key)"
		set returnMess [http::data [http::geturl $url]]
		if { [string compare $returnMess "ok"] != 0 } {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Is now downloading"
		} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Was not resumed for some reason" 
		}
	} elseif {([lindex $arg 0] == "version")} {
		set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=version&output=xml$sabUserPass&apikey=$sabnzbd(key)"
		set version [http::data [http::geturl $url]]
		set doc [dom parse $version]
		set root [$doc documentElement]
		set version [[$root selectNodes /versions/version/text()] data]
		putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Script Version:\002\[$sabnzbd(version)\]\002 SABnzbd Version:\002\[$version\]\002" 
	} elseif {([lindex $arg 0] == "speed")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot set a speedlimit"
			return
		}   
		if {([lindex $arg 1] != "") && ([string is integer -strict [lindex $arg 1]])} {
			set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?mode=speedlimit&value=[lindex $arg 1]$sabUserPass&apikey=$sabnzbd(key)"
			set returnMess [http::data [http::geturl $url]]
			if { [string compare $returnMess "ok"] != 0 } {
				if {([lindex $arg 1] == 0)} {
					putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Removed speedlimit"
				} else {
					putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Set speedlimit to [lindex $arg 1]KB/s"
				}
			} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Speedlimit not set for some reason" 
			}		
		} else {
			putserv "NOTICE $nick :Usage: !sabnzbd speedlimit <Speed in KB/s (0 to remove limit)>"
		}
	} elseif {([lindex $arg 0] == "help")} {
		putserv "NOTICE $nick :\002\[SABnzbd Usage\]\002"
                putserv "NOTICE $nick :\002\!sabnzbd stats\002 - Gives a quick breakdown current status"
		putserv "NOTICE $nick :\002\!sabnzbd queue \[n\]\002 - Shows current items in queue. Default is 3. Specify n to show more or less"
		putserv "NOTICE $nick :\002\!sabnzbd version\002 - Shows current version of SABnzbd and also this script"
		if {([lsearch -exact $sabnzbd(nicks) $nick] != -1)} { 
			putserv "NOTICE $nick :\002\!sabnzbd add <URL/Newzbin ID>\002 - Adds a URL or Newzbin ID to SABnzbd"
			putserv "NOTICE $nick :\002\!sabnzbd speed <Speed in KB/s (0 to remove limit)>\002 - Sets the speedlimit in SABnzbd"
			putserv "NOTICE $nick :\002\!sabnzbd pause\002 - Pauses SABnzbd"
			putserv "NOTICE $nick :\002\!sabnzbd resume\002 - Resumes SABnzbd"
		}
	} else {
		putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Type \"!sabnzbd help\" for more usage information"
	}
}
proc tvbinzTrigger { nick host hand chan arg } {
	global sabnzbd
	if {($sabnzbd(username) != "") && ($sabnzbd(password) != "")} {
		set sabUserPass "&ma_username=$sabnzbd(username)&ma_password=$sabnzbd(password)"
	}
	if {([lsearch -exact $sabnzbd(chans) $chan] == -1)} { return }    
	if {([lindex $arg 0] == "search")} {
		if {([lindex $arg 1] != "")} {
			if {[regexp {\-n([0-9]+)} [lindex $arg 1]]} {
				set urlEncode [lindex $arg 2 end]
				set noDisplay [string range [lindex $arg 1] 2 end]
			} else {
				set urlEncode [lindex $arg 1 end]
				set noDisplay 3
			}
#			set url "http://tvbinz.net/rss.php?$urlEncode"
#			set url "http://rss.nzbmatrix.com/rss.php?&term=$urlEncode&username=osmosis&apikey=07cc0f28add17eff41d4c37229213441"
			set url "http://www.newzbin.com/search/query/?q=$urlEncode&area=-1&fpn=p&searchaction=Go&areadone=-1&feed=rss&fauth=NjQwMjE4LTlhM2U4YzFiOWI0ZDMwNzkzNDk0OGYyNTYwMzY1OGIxMzMwMzQzMmI%3D"
			putserv "PRIVMSG $chan :$url"
			set searchResults [http::data [http::geturl $url -headers {Accept-Language {en-us,en;q=0.5}}]]
			set doc [dom parse $searchResults]
			set root [$doc documentElement]
			set items [$root selectNodes /rss/channel/item]
			set totalItems [llength $items]
			if {$totalItems != 0} {
				if {($totalItems < $noDisplay)} { 
					set showing $totalItems
				} else { set showing $noDisplay }
				putserv "PRIVMSG $chan :\002\[TVBINZ\]\002 Results:\002\[$totalItems\]\002 Displaying:\002\[$showing\]\002"
				foreach x $items {
					incr item
					set itemName [[$x selectNodes title/text()] data]
					set itemLink [[$x selectNodes link/text()] data]
					set itemDesc [[$x selectNodes description/text()] data]
					set itemId [lindex [split $itemLink "="] 2]
					set itemSize [string range [lindex [split $itemDesc "-"] 0] 0 [expr [string length [lindex [split $itemDesc "-"] 0]] - 2]]
					putserv "PRIVMSG $chan :ID:\002\[$itemId\]\002 Name:\002\[$itemName ($itemSize)\]\002"
					if {($item >= $noDisplay)} { return }
				}
			} else {
				putserv "PRIVMSG $chan :\002\[TVBINZ\]\002 No results for your query."
			}
		} else {
			putserv "PRIVMSG $chan :\002\[TVBINZ Search Results\]\002 You must specify a search term. Type !tvbinz help for more information"
		}
	} elseif {([lindex $arg 0] == "add")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot add an NZB."
			return
		}   
		if {([string is integer -strict [lindex $arg 1]])} {
			set tvbinzUrl "http://tvbinz.net/index.php?act=getnzb&c=[lindex $arg 1]"
			set urlEncode [http::formatQuery mode addurl name $tvbinzUrl ma_username $sabnzbd(username) ma_password $sabnzbd(password) apikey $sabnzbd(key)]
			set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?"
			set returnMess [http::data [http::geturl $url -query $urlEncode]]
			if { [string compare $returnMess "ok"] != 0 } {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item added successfully"
			} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item not added" 
			}
		} else {
			putserv "PRIVMSG $chan :\002\[TVBINZ\]\002 You must specify a valid TVBINZ ID. Type !tvbinz help for more information"
		}
	} elseif {([lindex $arg 0] == "help")} {
		putserv "NOTICE $nick :\002\[TVBINZ Usage\]\002"
		putserv "NOTICE $nick :\002\!tvbinz search \[-n<number of items to return>\] <search terms>\002 - Searches TVBINZ and returns results. Default is 3 results. Specify -n10 to show 10 results"
		if {([lsearch -exact $sabnzbd(nicks) $nick] != -1)} { 
			putserv "NOTICE $nick :\002\!tvbinz add <TVBINZ ID>\002 - Adds the specified ID to SABnzbd. The ID is returned by the search results"
		}
	} else {
		putserv "PRIVMSG $chan :\002\[TVBINZ\]\002 Type \"!tvbinz help\" for more usage information"
	}
	
}
proc nzbindexTrigger { nick host hand chan arg } {
	global sabnzbd
	if {($sabnzbd(username) != "") && ($sabnzbd(password) != "")} {
		set sabUserPass "&ma_username=$sabnzbd(username)&ma_password=$sabnzbd(password)"
	}
	if {([lsearch -exact $sabnzbd(chans) $chan] == -1)} { return }    
	if {([lindex $arg 0] == "search")} {
		if {([lindex $arg 1] != "")} {
			set argsEnd 1
			set min 0
			set max 0
			set noDisplay 3
			for { set i 1 } { $i <= [llength $arg] } { incr i } {
				set argu [lindex $arg $i]
				if {$argsEnd == 1} {
					incr searchStart
					if {[regexp {\-n([0-9]+)} $argu]} {
						set noDisplay [string range $argu 2 end]
					} elseif {[regexp {\-mi([0-9]+)} $argu]} {
						set min [string range $argu 3 end]
					} elseif {[regexp {\-ma([0-9]+)} $argu]} {
						set max [string range $argu 3 end]
					} else {
						set argsEnd 0
					}						
				}
			}
			set urlEncode [http::formatQuery searchitem [lindex $arg $searchStart end]]
			set url "http://nzbindex.nl/rss/?${urlEncode}&x=0&y=0&age=30&group=&min_size=${min}&max_size=${max}&poster="
			set searchResults [http::data [http::geturl $url -headers {Accept-Language {en-us,en;q=0.5}}]]
			set doc [dom parse $searchResults]
			set root [$doc documentElement]
			set items [$root selectNodes /rss/channel/item]
			set totalItems [llength $items]
			if {$totalItems != 0} {
				if {($totalItems < $noDisplay)} { 
					set showing $totalItems
				} else { set showing $noDisplay }
				putserv "PRIVMSG $chan :\002\[NZBIndex\]\002 Search For:\002\[[lindex $arg $searchStart end]\]\002 Min:\002\[${min}MB\]\002 Max:\002\[${max}MB\]\002 Results:\002\[$totalItems\]\002 Displaying:\002\[$showing\]\002"
				foreach x $items {
					incr item
					set itemName [[$x selectNodes title/text()] data]
					set itemLink [$x selectNodes enclosure/@url]
					set itemDesc [[$x selectNodes description/text()] data]
					regsub -all {<br />} $itemDesc "" itemDesc
					set doc1 [dom parse $itemDesc]
					set root1 [$doc1 documentElement]
					set nodeList [$root1 selectNodes /p/font/@color]
					set itemSize [[$root1 selectNodes /p/b/text()] data]
					set itemFiles [[lindex [$root1 selectNodes /p/font/text()] 1] data]
					set itemFilesTypes [[lindex [$root1 selectNodes /p/font/text()] 2] data]
					set itemFileTypes1 [split $itemFilesTypes "\n"]			
					set itemTypes ""
					for { set i 1 } { $i <= [expr [llength $itemFileTypes1] - 2] } { incr i } {
						set file [lindex $itemFileTypes1 $i]						
						regsub -all {files} $file "" file
						regsub -all {file} $file "" file
						set file [string trim $file]
						if {$i == 1} {
							set itemTypes "${file}"
						} else {
							set itemTypes "${itemTypes}, $file"
						}
					}
					set itemAge [string trim [[$root1 selectNodes /p/text()] data]]
					set itemColor [lindex [lindex $nodeList 1] 1 end]
					if {$itemColor == "#CA0000"} {
						set itemComplete "\00304$itemFiles\003"
					} elseif {$itemColor == "#21A517"} {
						set itemComplete "\00303$itemFiles\003"
					} else {
						set itemComplete "$itemFiles"
					}			
					set itemId [lindex [split [lindex [split $itemLink "="] 2] "&"] 0]
					putserv "PRIVMSG $chan :ID:\002\[$itemId\]\002 Name:\002\[$itemName\]\002 Size:\002\[$itemSize\]\002 Completeness:\002\[$itemComplete\]\002 Files:\002\[$itemTypes\]\002 Age:\002\[$itemAge\]\002"
					if {($item >= $noDisplay)} { return }
				}
			} else {
				putserv "PRIVMSG $chan :\002\[NZBIndex\]\002 No results for your query."
			}
		} else {
			putserv "PRIVMSG $chan :\002\[NZBIndex Search Results\]\002 You must specify a search term. Type !tvbinz help for more information"
		}
	} elseif {([lindex $arg 0] == "add")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot add an NZB."
			return
		}   
		if {([string is integer -strict [lindex $arg 1]])} {
			set tvbinzUrl "http://nzbindex.nl/?go=nzb&release=[lindex $arg 1]&t=[unixtime]"
			set urlEncode [http::formatQuery mode addurl name $tvbinzUrl ma_username $sabnzbd(username) ma_password $sabnzbd(password) apikey $sabnzbd(key)]
			set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?"
			set returnMess [http::data [http::geturl $url -query $urlEncode]]
			if { [string compare $returnMess "ok"] != 0 } {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item added successfully"
			} else {
				putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item not added" 
			}
		} else {
			putserv "PRIVMSG $chan :\002\[NZBIndex\]\002 You must specify a valid NZBIndex ID. Type !nzbindex help for more information"
		}
	} elseif {([lindex $arg 0] == "help")} {
		putserv "NOTICE $nick :\002\[NZBIndex Usage\]\002"
		putserv "NOTICE $nick :\002\!nzbindex search \[-n<number of items to return>\] \[-mi<minimum MB>\] \[-ma<maximum MB>\]  <search terms>\002 - Searches NZBIndex and returns results. Default is 3 results. Specify -n10 to show 10 results. Specify -mi100 to only show releases that are at last 100MB. Specify -ma1000 to only show releases that are smaller than 1000MB"
		if {([lsearch -exact $sabnzbd(nicks) $nick] != -1)} { 
			putserv "NOTICE $nick :\002\!nzbindex add <NZBIndex ID>\002 - Adds the specified ID to SABnzbd. The ID is returned by the search results"
		}
	} else {
		putserv "PRIVMSG $chan :\002\[NZBIndex\]\002 Type \"!nzbindex help\" for more usage information"
	}
	
}
proc binsearchTrigger { nick host hand chan arg } {
	global sabnzbd
	if {($sabnzbd(username) != "") && ($sabnzbd(password) != "")} {
		set sabUserPass "&ma_username=$sabnzbd(username)&ma_password=$sabnzbd(password)"
	}
	if {([lsearch -exact $sabnzbd(chans) $chan] == -1)} { return }    
	if {([lindex $arg 0] == "search")} {
		if {([lindex $arg 1] != "")} {
			set argsEnd 1
			set noDisplay 3
			for { set i 1 } { $i <= [llength $arg] } { incr i } {
				set argu [lindex $arg $i]
				if {$argsEnd == 1} {
					incr searchStart
					if {[regexp {\-n([0-9]+)} $argu]} {
						set noDisplay [string range $argu 2 end]
					} else {
						set argsEnd 0
					}						
				}
			}
#			set urlEncode [http::formatQuery term [lindex $arg $searchStart end]]
			set urlEncode [lindex $arg $searchStart end]
#			set url "http://www.binsearch.info/?${urlEncode}&max=25&adv_age=&server="
			set url "http://rss.nzbmatrix.com/rss.php?&term=${urlEncode}&username=osmosis&apikey=07cc0f28add17eff41d4c37229213441"
putserv "PRIVMSG $chan :$url"
			set searchResults [http::data [http::geturl $url -headers {Accept-Language {en-us,en;q=0.5}}]]
			set resultTableStart [string first "Group" $searchResults]
			set resultTable [string range $searchResults $resultTableStart end]
			set resultTableEnd [string first "</table>" $resultTable]
			set resultTable [string range $resultTable 0 $resultTableEnd]
			regsub -all {checkbox} $resultTable "\n" resultTable
			set items [split $resultTable "\n"]
			set totalItems [expr [llength $items] - 1]
			if {[string first "<i>No results</i><i> in most popular groups" $searchResults] == -1} {
				if {($totalItems < $noDisplay)} { 
					set showing $totalItems
				} else { set showing $noDisplay }
				putserv "PRIVMSG $chan :\002\[Binsearch\]\002 Search For:\002\[[lindex $arg $searchStart end]\]\002 Results:\002\[$totalItems\]\002 Displaying:\002\[$showing\]\002"
				for { set i 1 } { $i <= $showing } { incr i } {
					set x [lindex $items $i]
					set idFirst [string first "name=" $x]
					set idLast [string first "\" ><td>" $x]
					set itemId [string range $x [expr $idFirst + 6] [expr $idLast - 1]]
					
					set nameFirst [string first "<span class=\"s\">" $x]
					set nameLast [string first "</span>" $x]
					set itemName [string range $x [expr $nameFirst + 16] [expr $nameLast - 1]]
					regsub -all {&quot;} $itemName "" itemName
					if {[string first "collection</a>" $x] != -1} {
						set sizeStart [string first "</a> size:" $x]
						set itemSize [string range $x $sizeStart end]
						set sizeEnd [string first "," $itemSize]
						set itemSize [string range $itemSize 11 [expr $sizeEnd - 1]]
						
						if {[string first "<font color='red'>" $x] != -1} {
							set partsStart [string first "<font color='red'>" $x]
							set itemParts [string range $x $partsStart end]
							set partsEnd [string first "</font>" $itemParts]
							set itemParts "\00304[string range $itemParts 18 [expr $partsEnd - 1]]\003"
						} else {
							set partsStart [string first "parts available:" $x]
							set itemParts [string range $x $partsStart end]
							set partsEnd [string first "<br>" $itemParts]
							set itemParts "\00303[string range $itemParts 17 [expr $partsEnd - 1]]\003"
						}
						set filesStart [string first "<br>-" $x]
						set itemFiles [string range $x $filesStart end]
						set filesEnd [string first "<br><" $itemFiles]
						set itemFiles [string range $itemFiles 4 [expr $filesEnd - 1]]
						regsub -all {<br>} $itemFiles "\n" itemFiles
						set itemFiles [split $itemFiles "\n"]
						set itemTypes ""
						for { set j 0 } { $j < [llength $itemFiles] } { incr j } {
							set file [lindex $itemFiles $j]
							regsub -all {files} $file "" file
							regsub -all {file} $file "" file
							regsub -all {\-} $file "" file
							set file [string trim $file]
							if {$j == 0} {
								set itemTypes "${file}"
							} else {
								set itemTypes "${itemTypes}, $file"
							}
						}			
					} else {
						set itemTypes "N/A"
						set itemParts "N/A"
						set itemSize "N/A"
					}
					set ageStart [string first "bg=\"></a><td>" $x]
					set itemAge [string range $x $ageStart end]
					set ageEnd [string first "<tr" $itemAge]
					set itemAge [string range $itemAge 13 [expr $ageEnd - 1]]
					set itemAge "N/A"
					putserv "PRIVMSG $chan :ID:\002\[$itemId\]\002 Name:\002\[$itemName\]\002 Size:\002\[$itemSize\]\002 Parts:\002\[$itemParts\]\002 Files:\002\[$itemTypes\]\002 Age:\002\[$itemAge\]\002"
					#putlog "ID:\002\[$itemId\]\002 Name:\002\[$itemName\]\002 Size:\002\[$itemSize\]\002 Parts:\002\[$itemParts\]\002 Files:\002\[$itemTypes\]\002 Age:\002\[$itemAge\]\002"
				}
			} else {
				putserv "PRIVMSG $chan :\002\[Binsearch\]\002 No results for your query."
			}
		} else {
			putserv "PRIVMSG $chan :\002\[Binsearch Search Results\]\002 You must specify a search term. Type !tvbinz help for more information"
		}
	} elseif {([lindex $arg 0] == "add")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot add an NZB."
			return
		}
		if {[regexp {\-n.+} [lindex $arg 1]]} {
				set urlEncode [http::formatQuery q [string range [lindex $arg 1] 2 end]]
				set urlEncode "&$urlEncode"
				set idList [lrange $arg 2 end]
			} else {
				set urlEncode ""
				set idList [lrange $arg 1 end]
		}
		set collList ""
		foreach x $idList {
			if {([string is integer -strict $x])} {
				set collList "${collList}&${x}=on"
			}
		}
		set binsearchUrl "http://binsearch.info/?action=nzb$collList${urlEncode}"
		set urlEncode [http::formatQuery mode addurl name $binsearchUrl ma_username $sabnzbd(username) ma_password $sabnzbd(password) apikey $sabnzbd(key)]
		set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?"
		set returnMess [http::data [http::geturl $url -query $urlEncode]]
		if { [string compare $returnMess "ok"] != 0 } {
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item added successfully"
		} else {
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item not added" 
		}
	} elseif {([lindex $arg 0] == "help")} {
		putserv "NOTICE $nick :\002\[Binsearch Usage\]\002"
		putserv "NOTICE $nick :\002\!binsearch search \[-n<number of items to return>\] <search terms>\002 - Searches Binsearch and returns results. Default is 3 results. Specify -n10 to show 10 results."
		if {([lsearch -exact $sabnzbd(nicks) $nick] != -1)} { 
			putserv "NOTICE $nick :\002\!binsearch add \[-n<NZB Name>\] <Binsearch IDs>\002 - Adds the specified IDs to SABnzbd (you can specify more than 1 ID, seperate with spaces). Specify -nExampleNZBName to specify the name of the NZB being sent to SAB, if not set Binsearch will determine"
		}
	} else {
		putserv "PRIVMSG $chan :\002\[Binsearch\]\002 Type \"!binsearch help\" for more usage information"
	}	
}
proc getString {searchstr first last} {
	set start [string first $first $searchstr]
	set returnString [string range $searchstr $start end]
	set end [string first $last $returnString]
	set returnString [string range $returnString [string length $first] [expr $end - 1]]
	return $returnString
}
proc newzleechTrigger { nick host hand chan arg } {
	global sabnzbd
	if {($sabnzbd(username) != "") && ($sabnzbd(password) != "")} {
		set sabUserPass "&ma_username=$sabnzbd(username)&ma_password=$sabnzbd(password)"
	}
	if {([lsearch -exact $sabnzbd(chans) $chan] == -1)} { return }    
	if {([lindex $arg 0] == "search")} {
		if {([lindex $arg 1] != "")} {
			set argsEnd 1
			set noDisplay 3
			for { set i 1 } { $i <= [llength $arg] } { incr i } {
				set argu [lindex $arg $i]
				if {$argsEnd == 1} {
					incr searchStart
					if {[regexp {\-n([0-9]+)} $argu]} {
						set noDisplay [string range $argu 2 end]
					} else {
						set argsEnd 0
					}						
				}
			}
			set urlEncode [http::formatQuery q [lindex $arg $searchStart end]]
			set url "http://www.newzleech.com/?group=&minage=&age=&min=min&max=max&${urlEncode}&m=search&adv="
			set searchResults [http::data [http::geturl $url -headers {Accept-Language {en-us,en;q=0.5}}]]
			regsub -all {<table class="contentt">} $searchResults "\r" searchResults
			set resultsList [split $searchResults "\r"]
			set totalItems [expr [llength $resultsList] - 1]
			if {[string first "No results found</span>" $searchResults] == -1} {
				if {($totalItems < $noDisplay)} { 
					set showing $totalItems
				} else { set showing $noDisplay }
				putserv "PRIVMSG $chan :\002\[Newzleech\]\002 Search For:\002\[[lindex $arg $searchStart end]\]\002 Results:\002\[$totalItems\]\002 Displaying:\002\[$showing\]\002"
				for { set i 1 } { $i <= $showing } { incr i } {
					set x [lindex $resultsList $i]
					set itemSize [getString $x {<td class="size">} {</td>}]
					set itemId [getString $x {class="postinfo" id="} {"></div>}]
					regsub -all {p} $itemId "" itemId
					set itemName [getString $x {<td class="subject">} {</a>}]
					regsub -all {<div style="padding-left:15px;">} $itemName "" itemName
					set itemName [string range $itemName [expr [string first "\">" $itemName] + 2] end]
					regsub -all {&quot;} $itemName "" itemName
					regsub -all {<b>} $itemName "" itemName
					regsub -all {<b >} $itemName "" itemName
					regsub -all {</b>} $itemName "" itemName
					set itemFiles [getString $x {<td class="files">} {</td>}]
					set itemComplete [getString $x {<td class="complete">} {</td>}]
					if {$itemComplete < 100} {
						set itemComplete "\00304${itemComplete}%\003"
					} else {
						set itemComplete "\00303${itemComplete}%\003"
					}					
					set itemAge [getString $x {<td class="age">} {</td>}]
					putserv "PRIVMSG $chan :ID:\002\[$itemId\]\002 Name:\002\[$itemName\]\002 Size:\002\[$itemSize\]\002 Complete:\002\[${itemComplete}\]\002 Files:\002\[$itemFiles\]\002 Age:\002\[$itemAge\]\002"
				}
			} else {
				putserv "PRIVMSG $chan :\002\[Newzleech\]\002 No results for your query."
			}
		} else {
			putserv "PRIVMSG $chan :\002\[Newzleech Search Results\]\002 You must specify a search term. Type !tvbinz help for more information"
		}
	} elseif {([lindex $arg 0] == "add")} {
		if {([lsearch -exact $sabnzbd(nicks) $nick] == -1)} { 
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 You're not a valid user. You cannot add an NZB."
			return
		}
		if {[regexp {\-n.+} [lindex $arg 1]]} {
				set urlEncode [http::formatQuery q [string range [lindex $arg 1] 2 end]]
				set urlEncode "&$urlEncode"
				set idList [lrange $arg 2 end]
			} else {
				set urlEncode ""
				set idList [lrange $arg 1 end]
		}
		set collList ""
		foreach x $idList {
			if {([string is integer -strict $x])} {
				set collList "${collList}&binary%5B%5D=${x}"
			}
		}
		set newzleechUrl "http://newzleech.com/?m=gen&getnzb=Get+NZB&p=&mode=usenet&offset=0&type=&b=&group=&${urlEncode}&age=&get=0$collList"
		set urlEncode [http::formatQuery mode addurl name $newzleechUrl ma_username $sabnzbd(username) ma_password $sabnzbd(password) apikey $sabnzbd(key)]
		set url "http://$sabnzbd(host):$sabnzbd(port)/sabnzbd/api?"
		set returnMess [http::data [http::geturl $url -query $urlEncode]]
		if { [string compare $returnMess "ok"] != 0 } {
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item added successfully"
		} else {
			putserv "PRIVMSG $chan :\002\[SABnzbd\]\002 Item not added" 
		}
	} elseif {([lindex $arg 0] == "help")} {
		putserv "NOTICE $nick :\002\[Newzleech Usage\]\002"
		putserv "NOTICE $nick :\002\!newzleech search \[-n<number of items to return>\] <search terms>\002 - Searches Newzbin and returns results. Default is 3 results. Specify -n10 to show 10 results."
		if {([lsearch -exact $sabnzbd(nicks) $nick] != -1)} { 
			putserv "NOTICE $nick :\002\!newzleech add \[-n<NZB Name>\] <Newzleech IDs>\002 - Adds the specified IDs to SABnzbd (you can specify more than 1 ID, seperate with spaces). Specify -nExampleNZBName to specify the name of the NZB being sent to SAB, if not set Newzleech will determine it"
		}
	} else {
		putserv "PRIVMSG $chan :\002\[Newzleech\]\002 Type \"!newzleech help\" for more usage information"
	}	
}

putlog "SABnzbd Eggdrop Controller v$sabnzbd(version) by dr0pknutz loaded."

