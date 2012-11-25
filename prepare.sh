#!/bin/sh

#######################################################################
# Сценарій для підготування дисків до запису. Поки що ще дуже сирий:) #
#######################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

###########
# Функції #
###########

print_help () {
    echo "Використання: $0 ТЕКА_ДО_ЗАПИСУ [ІДЕНТИФІКАТОР_ДИСКА]"
}

list () {
    echo "Створення переліку файлів..."

    find . -type f > $LISTFILE
    gzip -c $LISTFILE > $LISTDIR/$VOLUMEID.filelist.gz
}

md5 () {
    echo "Створення відбитків md5..."

    cat $LISTFILE | xargs --delimiter "\n" -L 1 md5sum | tee $TMPDIR/$MD5FILE
    mv $TMPDIR/$MD5FILE $MD5FILE
}

md5sign () {
    echo "Підписування відбитків md5..."

    gpg --sign --armor $MD5FILE || echo "Підписування неможливе (немає ключа?). Відбитки md5 не будуть підписані."
}


##############
# Налаштунки #
##############
BASEDIR="$(pwd)"
LISTDIR="$(pwd)/_contents/"
TMPDIR=$(mktemp --directory --suffix=AR)
LISTFILE=$TMPDIR/files.txt
MD5FILE=md5sums.txt

#######
# Дія #
#######
DIR="$1"
VOLUMEID="$2"

if [ -z "$DIR" ]; then
    print_help
    exit 1
fi

if [ ! -d "$DIR" -o "$DIR" = "--help" -o "$DIR" = "-h" -o "$DIR" = "-?" ]; then
    echo "Не вказано правильної теки з файлами до запису."
    exit 1
fi

if [ -z "$VOLUMEID" ]; then
    VOLUMEID="$(basename "$DIR")"
fi

if [ ! -d "$LISTDIR" ]; then
    mkdir $LISTDIR || exit 1
fi

if [ ! -w "$LISTDIR" ]; then
    echo "Бракує дозволу запису у теку $LISTDIR"
    exit 1
fi

(cd "$DIR" && \
    list && \
    md5 && \
    md5sign
)

rm -fR $TMPDIR

echo "Операцію завершено."
