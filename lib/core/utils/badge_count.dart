/// The number an unread badge shows: the count itself up to [max], then
/// "99+" — a badge has room for two digits, not for the exact total.
String badgeCount(int count, {int max = 99}) =>
    count > max ? '$max+' : '$count';
