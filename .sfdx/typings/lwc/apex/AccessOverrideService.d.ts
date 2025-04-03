declare module "@salesforce/apex/AccessOverrideService.grantOverrideAccess" {
  export default function grantOverrideAccess(param: {userId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccessOverrideService.revokeOverrideAccess" {
  export default function revokeOverrideAccess(param: {userId: any, accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccessOverrideService.getAccountOverrides" {
  export default function getAccountOverrides(param: {accountId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccessOverrideService.getUserOverrides" {
  export default function getUserOverrides(param: {userId: any}): Promise<any>;
}
declare module "@salesforce/apex/AccessOverrideService.getEligibleUsersForOverride" {
  export default function getEligibleUsersForOverride(param: {accountId: any}): Promise<any>;
}
