export interface FeedSource {
  name: string
  url: string
  abbr: string  // 縮寫，用於顯示徽章
  utcOffset?: number  // UTC offset in minutes for feeds that publish timezone-less dates
}

export const FEEDS: FeedSource[] = [
  { name: 'The Hacker News',   url: 'https://feeds.feedburner.com/TheHackersNews',             abbr: 'THN' },
  { name: 'Krebs on Security', url: 'https://krebsonsecurity.com/feed/',                        abbr: 'KRB' },
  { name: 'BleepingComputer',  url: 'https://www.bleepingcomputer.com/feed/',                   abbr: 'BC'  },
  { name: 'SecurityWeek',      url: 'https://feeds.feedburner.com/securityweek',                abbr: 'SW'  },
  { name: 'SANS ISC',          url: 'https://isc.sans.edu/rssfeed_small.xml',                   abbr: 'ISC' },
  { name: 'Dark Reading',      url: 'https://www.darkreading.com/rss.xml',                      abbr: 'DR'  },
  { name: 'Infosecurity Mag',  url: 'https://www.infosecurity-magazine.com/rss/news/',          abbr: 'INF' },
  { name: 'CSO Online',        url: 'https://www.csoonline.com/feed/',                          abbr: 'CSO' },
  { name: 'Threatpost',        url: 'https://threatpost.com/feed/',                             abbr: 'TP'  },
  { name: 'CyberScoop',        url: 'https://cyberscoop.com/feed/',                             abbr: 'CS'  },
  { name: '資安人',             url: 'scrape:informationsecurity',                               abbr: '資安' },
  { name: 'iThome',            url: 'https://www.ithome.com.tw/rss/security',                   abbr: 'ITH', utcOffset: 480 },
]
