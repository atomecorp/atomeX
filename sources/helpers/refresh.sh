#modified_file="$1"
#
## $2 contient le type de dossier ("app" ou "sources")
#folder_type="$2"

cd  ../../sources/helpers
ruby ./refresh.rb "$@"
