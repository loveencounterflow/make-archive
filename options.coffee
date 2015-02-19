


module.exports =
  'output-homes': [
    '/Volumes/Storage/archive'
    '/Volumes/da bin ich'
    '/Volumes/mercury/archive'
    '/Volumes/hier ist er'
    # '/Users/flow/Dropbox'
    ]
  #.........................................................................................................
  # Some of the formats available (see `man hdiutil`):
  # UDRW - UDIF read/write image
  # UDRO - UDIF read-only image
  # UDCO - UDIF ADC-compressed image
  # UDZO - UDIF zlib-compressed image
  # UDBZ - UDIF bzip2-compressed image (OS X 10.4+ only)
  # UFBI - UDIF entire image with MD5 checksum
  # UDTO - DVD/CD-R master for export
  # UDxx - UDIF stub image
  # UDSP - SPARSE (grows with content)
  # UDSB - SPARSEBUNDLE (grows with content; bundle-backed)
  # 'archive-format': 'UDBZ'
  'archive-format': 'UDRW'
  # 'dryrun':         yes
  'max-backup-count': 3
