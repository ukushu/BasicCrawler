Connect me as submodule
This is NOT a package.

branch: main
```
git@github.com:ukushu/BasicCrawler.git
https://github.com/ukushu/BasicCrawler.git
```

Best practice to use this repo is:
1) use only functions from ```Crawl.swift``` & ```GSheets.swift``` documents
2) use them with https://github.com/phimage/Erik

OR

Use ```Erik``` only without this repository!

Important:
* Here is a lot of shit-code that must be not used at all -- especially in production :)
* This repo supports async and sync html download methods. Better to use only async!
* Better do not use functions with "Advanced" in name as they may crash your app. This functions needed only if not able get some html with "no-advanced" functions.
