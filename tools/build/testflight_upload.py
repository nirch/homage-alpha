import sys
import plistlib
import subprocess
import os
import shutil

URL = 'http://testflightapp.com/api/builds.format'
API_TOKEN = 'bfe244848d4b69fd7e4e3c6520c5d049_MTQ1MDM5MDIwMTMtMTEtMTcgMDQ6NDE6MTUuNDMxOTAw'
TEAM_TOKEN = 'a21634f841a92fc94ed23cabc91bf8b7_MzAwOTQ3MjAxMy0xMS0xNyAwNjozNzozMi4yMjAzOTA'

TEMP_FOLDER = '/tmp'

# def uploadIpa(
#         ipaPath=None,
#         dsymPath=None,
#         apiToken=None,
#         teamToken=None,
#         releaseNotes=None,
#         distributionLists=None,
#         notifiy=False):
#
#     if( ipaPath is None ):
#         print "You must supply a full path to an IPA file as the last parameter."
#         sys.exit( 1 )
#
#     if( apiToken is None ):
#         print "api_token is a required input"
#         sys.exit( 1 )
#
#     if( teamToken is None ):
#         print "team_token is a required input"
#         sys.exit( 1 )
#
#     cmd = [ "curl" ]
#     cmd.extend( [ "-F", buildCurlIpaFile( ipaPath ) ] )
#     if( dsymPath is not None ):
#         cmd.extend( [ "-F", buildCurlDsymFile( dsymPath ) ] )
#
#     cmd.extend( [ "--form-string", buildCurlParamter( "api_token", apiToken ) ] )
#     cmd.extend( [ "--form-string", buildCurlParamter( "team_token", teamToken ) ] )
#
#     if( not releaseNotes is None ):
#         cmd.extend( [ "--form-string", buildCurlParamter( "notes", releaseNotes ) ] )
#
#     if( not distributionLists is None ):
#         cmd.extend( [ "--form-string", buildCurlParamter( "distribution_lists", distributionLists ) ] )
#
#     if( notifiy ):
#         cmd.extend( [ "--form-string", buildCurlParamter( "notify", "True" ) ] )
#
#
#     cmd.extend( [ _testFlightAPIUrl ] )
#     cmd.extend( [ "-v", "--trace", "output.txt" ] ) # verbose
#
#     print "EXECUTING: " + " ".join( cmd )
#     subprocess.Popen( cmd ).communicate()

if __name__ == '__main__':

    # Get what is needed for upload from the archive
    archive_path = sys.argv[1]

    # read plist
    p = plistlib.readPlist(os.path.join(archive_path,'info.plist'))
    props = p['ApplicationProperties']
    bundle_identifier = props['CFBundleIdentifier']
    app_path = os.path.join('Products', props['ApplicationPath'])
    app_file = os.path.basename(app_path)
    dsym_path = os.path.join('dSYMs',app_file)+'.dSYM'

    tmp_ipa = 

    # copy ipa and dsym from archive to temp
    shutil.copy(src, dst)
