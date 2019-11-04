/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQml.Models 2.2

import org.videolan.vlc 0.1

import "qrc:///utils/" as Utils
import "qrc:///utils/KeyHelper.js" as KeyHelper
import "qrc:///style/"

Utils.NavigableFocusScope {
    id: root

    property var plmodel: PlaylistListModel {
        playlistId: mainctx.playlist
    }

    property int leftPadding: 0
    property int rightPadding: 0

    //label for DnD
    Utils.DNDLabel {
        id: dragItem
    }

    PlaylistMenu {
        id: overlayMenu
        anchors.fill: parent
        z: 2

        navigationParent: root
        navigationLeftItem: view

        leftPadding: root.leftPadding
        rightPadding: root.rightPadding

        //rootmenu
        Action { id:playAction;         text: qsTr("Play");             onTriggered: view.onPlay(); icon.source: "qrc:///toolbar/play_b.svg" }
        Action { id:deleteAction;       text: qsTr("Delete");           onTriggered: view.onDelete() }
        Action { id:clearAllAction;     text: qsTr("Clear Playlist");   onTriggered: mainPlaylistController.clear() }
        Action { id:selectAllAction;    text: qsTr("Select All");       onTriggered: root.plmodel.selectAll() }
        Action { id:shuffleAction;      text: qsTr("Suffle playlist");  onTriggered: mainPlaylistController.shuffle(); icon.source: "qrc:///buttons/playlist/shuffle_on.svg" }
        Action { id:sortAction;         text: qsTr("Sort");             property string subMenu: "sortmenu"}
        Action { id:selectTracksAction; text: qsTr("Select Tracks");    onTriggered: view.mode = "select" }
        Action { id:moveTracksAction;   text: qsTr("Move Selection");   onTriggered: view.mode = "move" }

        //sortmenu
        Action { id: sortTitleAction;   text: qsTr("Tile");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_TITLE, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortDurationAction;text: qsTr("Duration");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_DURATION, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortArtistAction;  text: qsTr("Artist");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_ARTIST, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortAlbumAction;   text: qsTr("Album");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_ALBUM, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortGenreAction;   text: qsTr("Genre");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_GENRE, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortDateAction;    text: qsTr("Date");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_DATE, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortTrackAction;   text: qsTr("Track number");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_TRACK_NUMBER, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortURLAction;     text: qsTr("URL");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_URL, PlaylistControllerModel.SORT_ORDER_ASC)}
        Action { id: sortRatingAction;  text: qsTr("Rating");
            onTriggered: mainPlaylistController.sort(PlaylistControllerModel.SORT_KEY_RATIN, PlaylistControllerModel.SORT_ORDER_ASC)}

        models: {
            "rootmenu" : {
                title: qsTr("Playlist"),
                entries: [
                    playAction,
                    deleteAction,
                    clearAllAction,
                    selectAllAction,
                    shuffleAction,
                    sortAction,
                    selectTracksAction,
                    moveTracksAction
                ]
            },
            "sortmenu" :{
                title: qsTr("Sort Playlist"),
                entries:  [
                    sortTitleAction,
                    sortDurationAction,
                    sortArtistAction,
                    sortAlbumAction,
                    sortGenreAction,
                    sortDateAction,
                    sortTrackAction,
                    sortURLAction,
                    sortRatingAction,
                ]
            }
        }
    }

    Utils.KeyNavigableListView {
        id: view

        anchors.fill: parent
        focus: true

        model: root.plmodel
        modelCount: root.plmodel.count

        property int shiftIndex: -1
        property string mode: "normal"

        Connections {
            target: root.plmodel
            onRowsInserted: {
                if (view.currentIndex == -1)
                    view.currentIndex = 0
            }
            onModelReset: {
                if (view.currentIndex == -1 &&  root.plmodel.count > 0)
                    view.currentIndex = 0
            }
        }

        footer: PLItemFooter {
            onDropURLAtEnd: mainPlaylistController.insert(root.plmodel.count, urlList)
            onMoveAtEnd: root.plmodel.moveItemsPost(root.plmodel.getSelection(), root.plmodel.count - 1)
        }

        delegate: PLItem {
            /*
             * implicit variables:
             *  - model: gives access to the values associated to PlaylistListModel roles
             *  - index: the index of this item in the list
             */
            id: plitem
            plmodel: root.plmodel
            width: root.width

            leftPadding: root.leftPadding
            rightPadding: root.rightPadding

            onItemClicked : {
                /* to receive keys events */
                view.forceActiveFocus()
                if (view.mode == "move") {
                    var selectedIndexes = root.plmodel.getSelection()
                    if (selectedIndexes.length === 0)
                        return
                    var preTarget = index
                    /* move to _above_ the clicked item if move up, but
                     * _below_ the clicked item if move down */
                    if (preTarget > selectedIndexes[0])
                        preTarget++
                    view.currentIndex = selectedIndexes[0]
                    root.plmodel.moveItemsPre(selectedIndexes, preTarget)
                } else if (view.mode == "select") {
                } else {
                    view.updateSelection(modifier, view.currentIndex, index)
                    view.currentIndex = index
                }
            }
            onItemDoubleClicked: mainPlaylistController.goTo(index, true)
            color: VLCStyle.colors.getBgColor(model.selected, plitem.hovered, plitem.activeFocus)

            onDragStarting: {
                if (!root.plmodel.isSelected(index)) {
                    /* the dragged item is not in the selection, replace the selection */
                    root.plmodel.setSelection([index])
                }
            }

            onDropedMovedAt: {
                if (drop.hasUrls) {
                    //force conversion to an actual list
                    var urlList = []
                    for ( var url in drop.urls)
                        urlList.push(drop.urls[url])
                    mainPlaylistController.insert(target, urlList)
                } else {
                    root.plmodel.moveItemsPre(root.plmodel.getSelection(), target)
                }
            }
        }

        onSelectAll: root.plmodel.selectAll()
        onSelectionUpdated: {
            if (view.mode === "select") {
                console.log("update selection select")
            } else if (mode == "move") {
                var selectedIndexes = root.plmodel.getSelection()
                if (selectedIndexes.length === 0)
                    return
                /* always move relative to the first item of the selection */
                var target = selectedIndexes[0];
                if (newIndex > oldIndex) {
                    /* move down */
                    target++
                } else if (newIndex < oldIndex && target > 0) {
                    /* move up */
                    target--
                }

                view.currentIndex = selectedIndexes[0]
                /* the target is the position _after_ the move is applied */
                root.plmodel.moveItemsPost(selectedIndexes, target)
            } else { // normal
                updateSelection(keyModifiers, oldIndex, newIndex);
            }
        }

        Keys.onDeletePressed: onDelete()
        Keys.onMenuPressed: overlayMenu.open()

        navigationParent: root
        navigationRight: function(index) {
            overlayMenu.open()
        }
        navigationLeft: function(index) {
            if (mode === "normal") {
                root.navigationLeft(index)
            } else {
                mode = "normal"
            }
        }
        navigationCancel: function(index) {
            if (mode === "normal") {
                root.navigationCancel(index)
            } else {
                mode = "normal"
            }
        }

        onActionAtIndex: {
            if (index < 0)
                return

            if (mode === "select")
                root.plmodel.toggleSelected(index)
            else //normal
                // play
                mainPlaylistController.goTo(index, true)
        }

        function onPlay() {
            let selection = root.plmodel.getSelection()
            if (selection.length === 0)
                return
            mainPlaylistController.goTo(selection[0], true)
        }

        function onDelete() {
            let selection = root.plmodel.getSelection()
            if (selection.length === 0)
                return
            root.plmodel.removeItems(selection)
        }

        function _addRange(from, to) {
            root.plmodel.setRangeSelected(from, to - from + 1, true)
        }

        function _delRange(from, to) {
            root.plmodel.setRangeSelected(from, to - from + 1, false)
        }

        // copied from SelectableDelegateModel, which is intended to be removed
        function updateSelection( keymodifiers, oldIndex, newIndex ) {
            if ((keymodifiers & Qt.ShiftModifier)) {
                if ( shiftIndex === oldIndex) {
                    if ( newIndex > shiftIndex )
                        _addRange(shiftIndex, newIndex)
                    else
                        _addRange(newIndex, shiftIndex)
                } else if (shiftIndex <= newIndex && newIndex < oldIndex) {
                    _delRange(newIndex + 1, oldIndex )
                } else if ( shiftIndex < oldIndex && oldIndex < newIndex ) {
                    _addRange(oldIndex, newIndex)
                } else if ( newIndex < shiftIndex && shiftIndex < oldIndex ) {
                    _delRange(shiftIndex, oldIndex)
                    _addRange(newIndex, shiftIndex)
                } else if ( newIndex < oldIndex && oldIndex < shiftIndex  ) {
                    _addRange(newIndex, oldIndex)
                } else if ( oldIndex <= shiftIndex && shiftIndex < newIndex ) {
                    _delRange(oldIndex, shiftIndex)
                    _addRange(shiftIndex, newIndex)
                } else if ( oldIndex < newIndex && newIndex <= shiftIndex  ) {
                    _delRange(oldIndex, newIndex - 1)
                }
            } else {
                shiftIndex = newIndex
                if (keymodifiers & Qt.ControlModifier) {
                    root.plmodel.toggleSelected(newIndex)
                } else {
                    root.plmodel.setSelection([newIndex])
                }
            }
        }

        Label {
            anchors.centerIn: parent
            visible: plmodel.count === 0
            font.pixelSize: VLCStyle.fontHeight_xxlarge
            color: view.activeFocus ? VLCStyle.colors.accent : VLCStyle.colors.text
            text: qsTr("playlist is empty")
        }
    }

    Keys.priority: Keys.AfterItem
    Keys.forwardTo: view
    Keys.onPressed: defaultKeyAction(event, 0)
}
