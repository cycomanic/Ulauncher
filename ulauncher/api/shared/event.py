from pickle import loads, dumps
from typing import Any, List


class BaseEvent:
    args: List[Any] = []

    def __eq__(self, other):
        return dumps(self) == dumps(other)

    def __ne__(self, other):
        return dumps(self) != dumps(other)


# pylint: disable=too-few-public-methods
class RegisterEvent(BaseEvent):
    """
    This event is triggered when a new extension connects to the server socket.
    """
    def __init__(self, extension_id):
        self.extension_id = extension_id


class KeywordQueryEvent(BaseEvent):
    """
    Is triggered when user enters query that starts with your keyword + Space

    :param ~ulauncher.modes.Query.Query query:
    """

    def __init__(self, query):
        self.query = query
        self.args = [query]

    def get_keyword(self):
        """
        :rtype: str
        """
        return self.query.keyword

    def get_query(self):
        """
        :rtype: :class:`~ulauncher.modes.Query.Query`
        """
        return self.query

    def get_argument(self):
        """
        :rtype: str
        :returns: None if arguments were not specified
        """
        return self.query.argument


# pylint: disable=too-few-public-methods
class ItemEnterEvent(BaseEvent):
    """
    Is triggered when selected item has action of type :class:`~ulauncher.api.shared.action.ExtensionCustomAction`
    Whatever data you've passed to action will be available in in this class using method :meth:`get_data`

    :param str data:
    """

    def __init__(self, data):
        self._data = data
        self.args = [data]

    def get_data(self):
        """
        :returns: whatever object you have passed to :class:`~ulauncher.api.shared.action.ExtensionCustomAction`
        """
        return loads(self._data)


class UnloadEvent(BaseEvent):
    """
    Is triggered when extension is about to be unloaded (terminated).

    Your extension has 300ms to handle this event and shut down properly.
    After that it will be terminated with SIGKILL
    """


class PreferencesUpdateEvent(BaseEvent):
    """
    Is triggered when user updates preference through Preferences window

    :param str id:
    :param str old_value:
    :param str new_value:
    """

    id = None
    old_value = None
    new_value = None

    def __init__(self, id, previous_value, value):
        self.id = id
        self.old_value = previous_value
        self.new_value = value
        self.args = [id, value, previous_value]


class PreferencesEvent(BaseEvent):
    """
    Is triggered on start

    :param dict preferences:
    """

    preferences = None

    def __init__(self, preferences):
        self.preferences = preferences
        self.args = [preferences]


# Alias of UnloadEvent for backward compatibility. In v6, please use UnloadEvent (or extension.on_unload) instead
SystemExitEvent = UnloadEvent
