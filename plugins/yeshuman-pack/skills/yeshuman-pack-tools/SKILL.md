---
name: yeshuman-pack-tools
description: Write or edit agent tools in a Yes Human tenant pack so they resolve the signed-in user with get_user_for_tool, include the record id on create and list, and accept that same id on read, update, and delete. Use when a change adds or edits tools on PLUGIN.tools, including when yeshuman-pack-feature sends you here.
---

# Agent tool contract

Apply this to every agent tool you add or edit. Registration stays on `PLUGIN.tools`, as `yeshuman-pack-feature` describes. This skill is how the tool resolves its user and how it names a record.

## Signed-in user

Resolve the user with `get_user_for_tool` from `tools.context`. Identity in the platform (`api/apps/accounts/account_identity_tools.py`; in a pack, `.platform/api/apps/accounts/account_identity_tools.py`) is the example. It loads the signed-in user from tool context.

A `user_id` argument that does not match that user is refused. Do not load a different account.

## Record id

Create and list include the record id. The id is the model's id as a string.

Read, update, and delete accept that same id. Pass that string through. Do not cast it with `int()`.

Delete is optional. When the tool has no delete, the description says so.

Prose or JSON is fine. The id has to be in the text either way.
