export class SyncContactItemDto {
  name: string;
  phoneNumber: string;
}

export class SyncContactsDto {
  userId?: string;
  contacts: SyncContactItemDto[];
}
