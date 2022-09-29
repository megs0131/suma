import api from "../api";
import DetailGrid from "../components/DetailGrid";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { dayjs } from "../modules/dayConfig";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { Divider, CircularProgress, Typography } from "@mui/material";
import _ from "lodash";
import React from "react";
import { useParams } from "react-router-dom";

export default function BankAccountDetailPage() {
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  let { id } = useParams();
  id = Number(id);
  const getBankAccount = React.useCallback(() => {
    return api
      .getBankAccount({ id })
      .catch((e) => enqueueErrorSnackbar(e, { variant: "error" }));
  }, [id, enqueueErrorSnackbar]);
  const { state: bankAccount, loading: bankAccountLoading } = useAsyncFetch(
    getBankAccount,
    {
      default: {},
      pickData: true,
    }
  );

  return (
    <>
      {bankAccountLoading && <CircularProgress />}
      {!_.isEmpty(bankAccount) && (
        <div>
          <Typography variant="h5" gutterBottom>
            Bank Account {id}
          </Typography>
          <Divider />
          <DetailGrid
            title="Account Information"
            properties={[
              { label: "ID", value: id },
              { label: "Name", value: bankAccount.display.name },
              { label: "Created At", value: dayjs(bankAccount.createdAt) },
              {
                label: "Deleted At",
                value: bankAccount.softDeletedAt ? dayjs(bankAccount.softDeletedAt) : "",
              },
              {
                label: "Verified At",
                value: bankAccount.verifiedAt
                  ? dayjs(bankAccount.verifiedAt).format("lll")
                  : "(not verified)",
              },
              { label: "Routing Number", value: bankAccount.routingNumber },
              { label: "Account Number", value: bankAccount.accountNumber },
              { label: "Account Type", value: bankAccount.accountType },
            ]}
          />
          {bankAccount.legalEntityDisplay && (
            <LegalEntity
              address={bankAccount.legalEntityDisplay.address}
              name={bankAccount.legalEntityDisplay.name}
            />
          )}
        </div>
      )}
    </>
  );
}

function LegalEntity({ name, address }) {
  if (_.isEmpty(address)) {
    return null;
  }
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    address || {};
  return (
    <div>
      <DetailGrid
        title="Legal Entity"
        properties={[
          { label: "Name", value: name },
          {
            label: "Street Address",
            value: [address1, address2].filter(Boolean).join(" "),
          },
          { label: "City", value: city },
          { label: "State", value: stateOrProvince },
          { label: "Postal Code", value: postalCode },
          { label: "Country", value: country },
        ]}
      />
    </div>
  );
}
