import clsx from "clsx";
import i18next from "i18next";
import React from "react";

export default function FormError({ error, noMargin, center, component, className }) {
  if (!error) {
    return null;
  }
  const Component = component || "p";
  const msg = React.isValidElement(error) ? error : i18next.t(error, { ns: "errors" });
  const cls = clsx(
    "d-block text-danger small",
    noMargin && "m-0",
    center && "text-center",
    className
  );
  return <Component className={cls}>{msg}</Component>;
}
