"""Add phone-confirmed OAuth viewer connections.

Revision ID: 0007_plugin
Revises: d001_sync
"""

from __future__ import annotations

import sqlalchemy as sa
from alembic import op

revision = "0007_plugin"
down_revision = "d001_sync"
branch_labels = None
depends_on = None


def upgrade() -> None:
    if not sa.inspect(op.get_bind()).has_table("plugin_grants"):
        op.create_table(
            "plugin_grants",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column(
                "workspace_id",
                sa.String(64),
                sa.ForeignKey("workspaces.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "device_id",
                sa.String(64),
                sa.ForeignKey("devices.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("client_id", sa.String(128), nullable=False),
            sa.Column("scopes", sa.Text(), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("revoked_at", sa.DateTime(timezone=True)),
        )
    if not sa.inspect(op.get_bind()).has_table("plugin_authorizations"):
        op.create_table(
            "plugin_authorizations",
            sa.Column("id", sa.String(64), primary_key=True),
            sa.Column("browser_hash", sa.String(64), nullable=False, unique=True),
            sa.Column("challenge_hash", sa.String(64), nullable=False),
            sa.Column("challenge_encrypted", sa.Text(), nullable=False),
            sa.Column("params", sa.JSON(), nullable=False),
            sa.Column("client_id", sa.String(128), nullable=False),
            sa.Column("status", sa.String(16), nullable=False),
            sa.Column(
                "grant_id", sa.String(64), sa.ForeignKey("plugin_grants.id", ondelete="CASCADE")
            ),
            sa.Column("code_hash", sa.String(64), unique=True),
            sa.Column("code_encrypted", sa.Text()),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("consumed_at", sa.DateTime(timezone=True)),
        )
    if not sa.inspect(op.get_bind()).has_table("plugin_tokens"):
        op.create_table(
            "plugin_tokens",
            sa.Column("token_hash", sa.String(64), primary_key=True),
            sa.Column(
                "grant_id",
                sa.String(64),
                sa.ForeignKey("plugin_grants.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column("kind", sa.String(16), nullable=False),
            sa.Column("scopes", sa.Text(), nullable=False),
            sa.Column("resource", sa.String(512), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
            sa.Column("consumed_at", sa.DateTime(timezone=True)),
        )
    for table, columns in {
        "plugin_grants": ["workspace_id", "device_id"],
        "plugin_authorizations": ["grant_id", "expires_at"],
        "plugin_tokens": ["grant_id", "expires_at"],
    }.items():
        for column in columns:
            name = f"ix_{table}_{column}"
            existing = {index["name"] for index in sa.inspect(op.get_bind()).get_indexes(table)}
            if name not in existing:
                op.create_index(name, table, [column])


def downgrade() -> None:
    for table in ("plugin_tokens", "plugin_authorizations", "plugin_grants"):
        op.drop_table(table)
