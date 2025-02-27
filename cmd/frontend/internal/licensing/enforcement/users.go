package enforcement

import (
	"context"
	"fmt"

	"github.com/inconshreveable/log15" //nolint:logging // TODO move all logging to sourcegraph/log

	"github.com/sourcegraph/sourcegraph/internal/actor"
	"github.com/sourcegraph/sourcegraph/internal/auth"
	"github.com/sourcegraph/sourcegraph/internal/cloud"
	"github.com/sourcegraph/sourcegraph/internal/database"
	"github.com/sourcegraph/sourcegraph/internal/dotcom"
	"github.com/sourcegraph/sourcegraph/internal/errcode"
	"github.com/sourcegraph/sourcegraph/internal/extsvc"
	"github.com/sourcegraph/sourcegraph/internal/licensing"
	"github.com/sourcegraph/sourcegraph/internal/types"
	"github.com/sourcegraph/sourcegraph/lib/errors"
)

// NewBeforeCreateUserHook returns a BeforeCreateUserHook closure with the given UsersStore
// that determines whether new user is allowed to be created.
func NewBeforeCreateUserHook() func(context.Context, database.DB, *extsvc.AccountSpec) error {
	return func(ctx context.Context, db database.DB, spec *extsvc.AccountSpec) error {
		// Always allow user creation
		return nil
	}
}

// NewAfterCreateUserHook returns a AfterCreateUserHook closure that determines whether
// a new user should be promoted to site admin based on the product license.
func NewAfterCreateUserHook() func(context.Context, database.DB, *types.User) error {
	return func(ctx context.Context, tx database.DB, user *types.User) error {
		// 🚨 SECURITY: To be extra safe that we never promote any new user to be site admin on Sourcegraph Cloud.
		if dotcom.SourcegraphDotComMode() {
			return nil
		}
		info, err := licensing.GetConfiguredProductLicenseInfo()
		if err != nil {
			return err
		}

		if info.Plan().IsFreePlan() {
			store := tx.Users()
			user.SiteAdmin = true
			if err := store.SetIsSiteAdmin(ctx, user.ID, user.SiteAdmin); err != nil {
				return err
			}
		}

		return nil
	}
}

// NewBeforeSetUserIsSiteAdmin returns a BeforeSetUserIsSiteAdmin closure that determines whether
// the creation or removal of site admins are allowed.
func NewBeforeSetUserIsSiteAdmin() func(ctx context.Context, isSiteAdmin bool) error {
	return func(ctx context.Context, isSiteAdmin bool) error {
		// Always allow site admin creation/removal
		return nil
	}
}