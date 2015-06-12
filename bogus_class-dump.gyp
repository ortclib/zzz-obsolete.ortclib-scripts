# Copyright (c) 2013 The WebRTC project authors. All Rights Reserved.
#
# Use of this source code is governed by a BSD-style license
# that can be found in the LICENSE file in the root of the source
# tree. An additional intellectual property rights grant can be found
# in the file PATENTS.  All contributing project authors may
# be found in the AUTHORS file in the root of the source tree.

#this is bogus file to be used as a placeholder for missing gyp files during ORTC project creation.

{
  'targets': [
    {
      'target_name': 'class-dump',
      'toolsets': ['host'],
      'type': 'executable',
      'sources': [
      ],
      'libraries': [
        '$(SDKROOT)/System/Library/Frameworks/Foundation.framework',
        '$(SDKROOT)/usr/lib/libcrypto.dylib',
      ],
      'xcode_settings': {
        'WARNING_CFLAGS': [
          '-Wno-format',
          '-Wno-deprecated',
        ],
      },
    },
  ],  # targets
}
